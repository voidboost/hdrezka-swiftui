import AVKit
import Combine
import Defaults
import Dependencies
import Kingfisher
import MediaPlayer
import SwiftUI

enum PlayerEvent: Sendable {
    enum RemoteCommand: Sendable {
        case play
        case pause
        case togglePlayPause
        case changePosition(Double)
        case changeRate(Float)
        case skip(Double)
        case previousTrack
        case nextTrack
    }

    case time(Double)
    case positionTick(Double)
    case status(AVPlayer.Status)
    case timeControlStatus(AVPlayer.TimeControlStatus)
    case isMuted(Bool)
    case volume(Float)
    case duration(Double)
    case loadedTimeRanges([CMTimeRange])
    case failed(any Error)
    case didPlayToEnd
    case routesDetected(Bool)
    case pictureInPictureActive(Bool)
    case pictureInPicturePossible(Bool)
    case remote(RemoteCommand)
}

struct SubtitleOption: Equatable, Hashable, Identifiable, Sendable {
    let tag: String
    let displayName: String

    var id: String {
        tag
    }
}

/// AVFoundation side of the player: owns the AVPlayer, its layer, Picture in Picture, Now Playing and remote commands.
/// `PlayerFeature` drives it with commands and consumes its state changes as `PlayerEvent`s.
@Observable
@MainActor
final class PlayerEngine {
    struct Configuration: Sendable {
        let urls: [URL]
        let subtitles: [MovieSubtitles]
        let title: String
        let album: String
        let artist: String?
        let poster: String
        let videoGravity: VideoGravity
        let ambientLight: Bool
        let volume: Float
        let isMuted: Bool
        let rate: Float
    }

    enum TrackCommandMode: Sendable {
        case none
        case episodes(hasPrevious: Bool, hasNext: Bool)
        case seeking
    }

    static let rates: [Float] = [0.5, 1.0, 1.25, 1.5, 2.0]

    @ObservationIgnored let playerLayer = AVPlayerLayer()

    private(set) var player: AVPlayer?
    private(set) var pipController: AVPictureInPictureController?
    private(set) var glowImage: Image?

    @ObservationIgnored @Dependency(\.notificationCenter) private var notificationCenter

    @ObservationIgnored private let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    @ObservationIgnored private let remoteCommandCenter = MPRemoteCommandCenter.shared()
    @ObservationIgnored private let routeDetector = AVRouteDetector()
    @ObservationIgnored private let glowRenderer = GlowRenderer()

    @ObservationIgnored private var continuation: AsyncStream<PlayerEvent>.Continuation?
    @ObservationIgnored private var observations: [Task<Void, Never>] = []
    @ObservationIgnored private var timeObserver: Any?
    @ObservationIgnored private var lastTime: CMTime?
    @ObservationIgnored private var lastPositionTick: ContinuousClock.Instant?
    @ObservationIgnored private var isAmbientLightVisible = false
    @ObservationIgnored private var rate: Float = Defaults[.rate]

    func load(_ configuration: Configuration) -> AsyncStream<PlayerEvent> {
        reset()

        let (stream, continuation) = AsyncStream.makeStream(of: PlayerEvent.self)

        guard let player = CustomAVPlayer(urls: configuration.urls, subtitles: configuration.subtitles),
              let currentItem = player.currentItem
        else {
            continuation.finish()

            return stream
        }

        self.continuation = continuation

        rate = configuration.rate

        let pipController = AVPictureInPictureController(playerLayer: playerLayer)

        setAmbientLight(configuration.ambientLight, item: currentItem)

        playerLayer.videoGravity = configuration.videoGravity.gravity

        nowPlayingInfoCenter.nowPlayingInfo = [:]

        routeDetector.isRouteDetectionEnabled = true

        glowRenderer.onImage = { [weak self] cgImage in
            guard let self, self.isAmbientLightVisible, self.playerLayer.player != nil else { return }

            if self.glowImage == nil {
                withAnimation(.easeInOut(duration: 0.15)) {
                    self.glowImage = Image(decorative: cgImage, scale: 1.0)
                }
            } else {
                self.glowImage = Image(decorative: cgImage, scale: 1.0)
            }
        }

        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: .main) { [weak self] time in
            MainActor.assumeIsolated {
                self?.handleTime(time, player: player, item: currentItem)
            }
        }

        observe(player.publisher(for: \.status)) { $0.yield(.status($1)) }

        observe(player.publisher(for: \.timeControlStatus)) { [weak self] continuation, status in
            self?.nowPlayingInfoCenter.playbackState = status == .playing ? .playing : .paused

            continuation.yield(.timeControlStatus(status))
        }

        observe(player.publisher(for: \.isMuted)) { $0.yield(.isMuted($1)) }

        observe(player.publisher(for: \.volume)) { $0.yield(.volume($1)) }

        observe(player.publisher(for: \.error).compactMap(\.self)) { $0.yield(.failed(handleError($1))) }

        observe(
            currentItem.publisher(for: \.duration)
                .filter { $0.isValid && !$0.isIndefinite && !$0.isNegativeInfinity && !$0.isPositiveInfinity && $0.seconds > 0 }
        ) { [weak self] continuation, duration in
            self?.nowPlayingInfoCenter.nowPlayingInfo?[MPMediaItemPropertyPlaybackDuration] = duration.seconds

            continuation.yield(.duration(duration.seconds))
        }

        observe(currentItem.publisher(for: \.loadedTimeRanges).compactMap { $0 as? [CMTimeRange] }.removeDuplicates()) { $0.yield(.loadedTimeRanges($1)) }

        observe(currentItem.publisher(for: \.error).compactMap(\.self)) { $0.yield(.failed(handleError($1))) }

        if let pipController {
            observe(pipController.publisher(for: \.isPictureInPictureActive)) { continuation, isActive in
                if !isActive, let window = Windows.player.window {
                    window.makeKeyAndOrderFront(nil)
                }

                continuation.yield(.pictureInPictureActive(isActive))
            }

            observe(pipController.publisher(for: \.isPictureInPicturePossible)) { $0.yield(.pictureInPicturePossible($1)) }
        }

        observations.append(Task { [weak self, notificationCenter] in
            for await _ in notificationCenter.notifications(named: AVPlayerItem.didPlayToEndTimeNotification, object: currentItem) {
                self?.continuation?.yield(.didPlayToEnd)
            }
        })

        observations.append(Task { [weak self, notificationCenter] in
            for await notification in notificationCenter.notifications(named: AVPlayerItem.failedToPlayToEndTimeNotification, object: currentItem) {
                guard let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error else { continue }

                self?.continuation?.yield(.failed(handleError(error)))
            }
        })

        continuation.yield(.routesDetected(routeDetector.multipleRoutesDetected))

        observations.append(Task { [weak self, notificationCenter] in
            for await _ in notificationCenter.notifications(named: .AVRouteDetectorMultipleRoutesDetectedDidChange) {
                guard let self else { return }

                self.continuation?.yield(.routesDetected(self.routeDetector.multipleRoutesDetected))
            }
        })

        setupNowPlaying(configuration, url: configuration.urls.first)
        setupRemoteCommands(continuation)

        player.volume = configuration.volume
        player.isMuted = configuration.isMuted

        withAnimation(.easeInOut) {
            playerLayer.player = player
            self.player = player
            self.pipController = pipController
        }

        return stream
    }

    func reset() {
        continuation?.finish()
        continuation = nil

        observations.forEach { $0.cancel() }
        observations = []

        if let timeObserver {
            player?.removeTimeObserver(timeObserver)
        }

        timeObserver = nil
        lastTime = nil
        lastPositionTick = nil

        nowPlayingInfoCenter.playbackState = .stopped
        nowPlayingInfoCenter.nowPlayingInfo = nil

        remoteCommandCenter.playCommand.removeTarget(nil)
        remoteCommandCenter.pauseCommand.removeTarget(nil)
        remoteCommandCenter.togglePlayPauseCommand.removeTarget(nil)
        remoteCommandCenter.changePlaybackPositionCommand.removeTarget(nil)
        remoteCommandCenter.changePlaybackRateCommand.removeTarget(nil)
        remoteCommandCenter.stopCommand.removeTarget(nil)
        remoteCommandCenter.previousTrackCommand.removeTarget(nil)
        remoteCommandCenter.nextTrackCommand.removeTarget(nil)
        remoteCommandCenter.skipBackwardCommand.removeTarget(nil)
        remoteCommandCenter.skipForwardCommand.removeTarget(nil)

        routeDetector.isRouteDetectionEnabled = false

        if let currentItem = playerLayer.player?.currentItem {
            for output in currentItem.outputs {
                currentItem.remove(output)
            }
        }

        playerLayer.player?.pause()
        playerLayer.player?.replaceCurrentItem(with: nil)

        withAnimation(.easeInOut) {
            playerLayer.player = nil
            player = nil
            pipController = nil
            glowImage = nil
        }
    }

    func play(rate: Float) {
        player?.playImmediately(atRate: rate)
    }

    func pause() {
        player?.pause()
    }

    func seek(to seconds: Double) async -> Bool {
        guard let player else { return false }

        return await player.seek(to: CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func setVolume(_ volume: Float) {
        player?.volume = volume
    }

    func setMuted(_ isMuted: Bool) {
        player?.isMuted = isMuted
    }

    func toggleMute() {
        player?.isMuted.toggle()
    }

    func setRate(_ rate: Float, isPlaying: Bool) {
        self.rate = rate

        nowPlayingInfoCenter.nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = rate

        if isPlaying {
            player?.playImmediately(atRate: rate)
        }
    }

    func setVideoGravity(_ videoGravity: VideoGravity) {
        playerLayer.videoGravity = videoGravity.gravity
    }

    func setAmbientLight(_ isVisible: Bool) {
        guard let currentItem = player?.currentItem else { return }

        setAmbientLight(isVisible, item: currentItem)
    }

    func setSpatialAudio(_ spatialAudio: SpatialAudio) {
        player?.currentItem?.allowedAudioSpatializationFormats = spatialAudio.format
    }

    func subtitleOptions(selecting language: String?) async -> [SubtitleOption] {
        guard let currentItem = player?.currentItem,
              let group = try? await currentItem.asset.loadMediaSelectionGroup(for: .legible)
        else {
            return []
        }

        let options = group.options.filter { $0.extendedLanguageTag != nil }

        currentItem.select(options.first(where: { $0.extendedLanguageTag == language }), in: group)

        return options.compactMap { option in
            option.extendedLanguageTag.map { SubtitleOption(tag: $0, displayName: option.displayName(with: Locale.current)) }
        }
    }

    func selectSubtitles(_ language: String?) async -> Bool {
        guard let currentItem = player?.currentItem,
              let group = try? await currentItem.asset.loadMediaSelectionGroup(for: .legible)
        else {
            return false
        }

        currentItem.select(group.options.filter { $0.extendedLanguageTag != nil }.first(where: { $0.extendedLanguageTag == language }), in: group)

        return true
    }

    func configureTrackCommands(_ mode: TrackCommandMode) {
        remoteCommandCenter.previousTrackCommand.removeTarget(nil)
        remoteCommandCenter.nextTrackCommand.removeTarget(nil)

        guard let continuation else { return }

        switch mode {
        case .none:
            break
        case let .episodes(hasPrevious, hasNext):
            remoteCommandCenter.previousTrackCommand.addTarget { @Sendable _ in
                continuation.yield(.remote(.previousTrack))

                return .success
            }

            remoteCommandCenter.nextTrackCommand.addTarget { @Sendable _ in
                continuation.yield(.remote(.nextTrack))

                return .success
            }

            remoteCommandCenter.previousTrackCommand.isEnabled = hasPrevious
            remoteCommandCenter.nextTrackCommand.isEnabled = hasNext
        case .seeking:
            remoteCommandCenter.previousTrackCommand.addTarget { @Sendable _ in
                continuation.yield(.remote(.skip(-10.0)))

                return .success
            }

            remoteCommandCenter.nextTrackCommand.addTarget { @Sendable _ in
                continuation.yield(.remote(.skip(10.0)))

                return .success
            }

            remoteCommandCenter.previousTrackCommand.isEnabled = true
            remoteCommandCenter.nextTrackCommand.isEnabled = true
        }
    }

    func startPictureInPicture() {
        pipController?.startPictureInPicture()
    }

    func stopPictureInPicture() {
        pipController?.stopPictureInPicture()
    }

    func showCursor(_ isShowed: Bool = true) {
        if isShowed {
            NSCursor.unhide()
        } else {
            NSCursor.setHiddenUntilMouseMoves(true)
        }
    }

    private func observe<P: Publisher>(_ publisher: P, _ handler: @escaping (AsyncStream<PlayerEvent>.Continuation, P.Output) -> Void) where P.Failure == Never {
        guard let continuation else { return }

        observations.append(Task {
            for await value in publisher.buffer(size: 32, prefetch: .byRequest, whenFull: .dropOldest).values {
                handler(continuation, value)
            }
        })
    }

    private func handleTime(_ time: CMTime, player: AVPlayer, item: AVPlayerItem) {
        guard time != lastTime else { return }

        lastTime = time

        continuation?.yield(.time(time.seconds))

        if isAmbientLightVisible {
            glowRenderer.render(at: CMTime(seconds: time.seconds + 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
        }

        let now = ContinuousClock.now

        guard lastPositionTick.map({ now - $0 >= .seconds(1) }) ?? true else { return }

        lastPositionTick = now

        updateNowPlayingInfo([
            MPNowPlayingInfoPropertyElapsedPlaybackTime: time.seconds,
            MPNowPlayingInfoPropertyPlaybackRate: rate,
            MPNowPlayingInfoPropertyCurrentPlaybackDate: item.currentDate(),
            MPNowPlayingInfoPropertyDefaultPlaybackRate: player.defaultRate,
        ])

        continuation?.yield(.positionTick(time.seconds))
    }

    private func setAmbientLight(_ isVisible: Bool, item: AVPlayerItem) {
        isAmbientLightVisible = isVisible

        for output in item.outputs {
            item.remove(output)
        }

        if isVisible {
            item.add(glowRenderer.videoOutput)
        } else {
            withAnimation(.easeInOut(duration: 0.15)) {
                glowImage = nil
            }
        }
    }

    private func setupNowPlaying(_ configuration: Configuration, url: URL?) {
        updateNowPlayingInfo([
            MPNowPlayingInfoPropertyAssetURL: url,
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.video.rawValue,
            MPNowPlayingInfoPropertyIsLiveStream: false,
            MPMediaItemPropertyTitle: configuration.title,
            MPMediaItemPropertyAlbumTitle: configuration.album,
        ])

        if let artist = configuration.artist {
            nowPlayingInfoCenter.nowPlayingInfo?[MPMediaItemPropertyArtist] = artist
        }

        if let url = URL(string: configuration.poster) {
            observations.append(Task { [weak self] in
                guard let image = try? await KingfisherManager.shared.retrieveImage(with: url).image else { return }

                self?.nowPlayingInfoCenter.nowPlayingInfo?[MPMediaItemPropertyArtwork] = Self.artwork(image)
            })
        }
    }

    /// Remote command handlers may be called off the main thread, so they only hand events to the (thread-safe) continuation.
    private func setupRemoteCommands(_ continuation: AsyncStream<PlayerEvent>.Continuation) {
        remoteCommandCenter.playCommand.addTarget { @Sendable _ in
            continuation.yield(.remote(.play))

            return .success
        }

        remoteCommandCenter.pauseCommand.addTarget { @Sendable _ in
            continuation.yield(.remote(.pause))

            return .success
        }

        remoteCommandCenter.togglePlayPauseCommand.addTarget { @Sendable _ in
            continuation.yield(.remote(.togglePlayPause))

            return .success
        }

        remoteCommandCenter.changePlaybackPositionCommand.addTarget { @Sendable event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }

            continuation.yield(.remote(.changePosition(event.positionTime)))

            return .success
        }

        remoteCommandCenter.changePlaybackRateCommand.addTarget { @Sendable event in
            guard let event = event as? MPChangePlaybackRateCommandEvent else { return .commandFailed }

            continuation.yield(.remote(.changeRate(event.playbackRate)))

            return .success
        }

        remoteCommandCenter.skipBackwardCommand.addTarget { @Sendable event in
            guard let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }

            continuation.yield(.remote(.skip(-event.interval)))

            return .success
        }

        remoteCommandCenter.skipForwardCommand.addTarget { @Sendable event in
            guard let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }

            continuation.yield(.remote(.skip(event.interval)))

            return .success
        }

        remoteCommandCenter.pauseCommand.isEnabled = true
        remoteCommandCenter.playCommand.isEnabled = true
        remoteCommandCenter.togglePlayPauseCommand.isEnabled = true
        remoteCommandCenter.changePlaybackPositionCommand.isEnabled = true
        remoteCommandCenter.changePlaybackRateCommand.isEnabled = true
        remoteCommandCenter.changePlaybackRateCommand.supportedPlaybackRates = Self.rates.map { NSNumber(value: $0) }
        remoteCommandCenter.skipBackwardCommand.isEnabled = true
        remoteCommandCenter.skipBackwardCommand.preferredIntervals = [10]
        remoteCommandCenter.skipForwardCommand.isEnabled = true
        remoteCommandCenter.skipForwardCommand.preferredIntervals = [10]

        remoteCommandCenter.previousTrackCommand.isEnabled = false
        remoteCommandCenter.nextTrackCommand.isEnabled = false
        remoteCommandCenter.stopCommand.isEnabled = false
        remoteCommandCenter.changeRepeatModeCommand.isEnabled = false
        remoteCommandCenter.enableLanguageOptionCommand.isEnabled = false
        remoteCommandCenter.changeShuffleModeCommand.isEnabled = false
        remoteCommandCenter.ratingCommand.isEnabled = false
        remoteCommandCenter.likeCommand.isEnabled = false
        remoteCommandCenter.dislikeCommand.isEnabled = false
        remoteCommandCenter.seekForwardCommand.isEnabled = false
        remoteCommandCenter.seekBackwardCommand.isEnabled = false
        remoteCommandCenter.bookmarkCommand.isEnabled = false
        remoteCommandCenter.disableLanguageOptionCommand.isEnabled = false
    }

    private func updateNowPlayingInfo(_ changes: [String: Any?]) {
        guard var info = nowPlayingInfoCenter.nowPlayingInfo else { return }

        for (key, value) in changes {
            info[key] = value
        }

        nowPlayingInfoCenter.nowPlayingInfo = info
    }

    private nonisolated static func artwork(_ image: NSImage) -> MPMediaItemArtwork {
        MPMediaItemArtwork(boundsSize: image.size) { _ in image }
    }
}
