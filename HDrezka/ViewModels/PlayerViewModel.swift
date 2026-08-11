import AVKit
import Combine
import Defaults
import FactoryKit
import Kingfisher
import MediaPlayer
import SwiftData
import SwiftUI

@Observable
class PlayerViewModel {
    @ObservationIgnored @LazyInjected(\.saveWatchingStateUseCase) private var saveWatchingStateUseCase
    @ObservationIgnored @LazyInjected(\.getMovieThumbnailsUseCase) private var getMovieThumbnailsUseCase
    @ObservationIgnored @LazyInjected(\.getMovieVideoUseCase) private var getMovieVideoUseCase
    @ObservationIgnored @LazyInjected(\.modelContainer) private var modelContainer

    @ObservationIgnored private var subscriptions: Set<AnyCancellable> = []

    @ObservationIgnored private let poster: String
    @ObservationIgnored let name: String
    @ObservationIgnored private let favs: String
    @ObservationIgnored let voiceActing: MovieVoiceActing

    @ObservationIgnored let hideMainWindow: Bool = Defaults[.hideMainWindow]

    @ObservationIgnored let times: [Int]

    private(set) var seasons: [MovieSeason]?
    private(set) var season: MovieSeason?
    private(set) var episode: MovieEpisode?
    private(set) var movie: MovieVideo
    var quality: String

    init(poster: String, name: String, favs: String, voiceActing: MovieVoiceActing, seasons: [MovieSeason]?, season: MovieSeason?, episode: MovieEpisode?, movie: MovieVideo, quality: String) {
        self.poster = poster
        self.name = name
        self.favs = favs
        self.voiceActing = voiceActing
        self.seasons = seasons
        self.season = season
        self.episode = episode
        self.movie = movie
        self.quality = quality

        times = seasons != nil && season != nil && episode != nil ? [900, 1800, 2700, 3600, -1] : [900, 1800, 2700, 3600]
    }

    deinit {
        resetPlayer()
    }

    var isSeries: Bool {
        seasons != nil && season != nil && episode != nil
    }

    var hasPrevoiusEpisode: Bool {
        guard let seasons, let season, let episode else { return false }

        return seasons.element(before: season) != nil || season.episodes.element(before: episode) != nil
    }

    var hasNextEpisode: Bool {
        guard let seasons, let season, let episode else { return false }

        return seasons.element(after: season) != nil || season.episodes.element(after: episode) != nil
    }

    @ObservationIgnored private let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    @ObservationIgnored private let remoteCommandCenter = MPRemoteCommandCenter.shared()

    @ObservationIgnored let playerLayer: AVPlayerLayer = .init()
    @ObservationIgnored let rates: [Float] = [0.5, 1.0, 1.25, 1.5, 2.0]

    @ObservationIgnored private let routeDetector: AVRouteDetector = .init()

    @ObservationIgnored private let videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)])
    @ObservationIgnored private let ciContext = CIContext(options: [.useSoftwareRenderer: false, .cacheIntermediates: false])

    private(set) var glowImage: Image?
    private(set) var routesDetected: Bool = false
    private(set) var pipController: AVPictureInPictureController?
    private(set) var isPictureInPictureActive: Bool = false
    private(set) var isPictureInPicturePossible: Bool = false
    private(set) var loadedTimeRanges: [CMTimeRange] = []
    var timer: Int?
    private var timerTask: Task<Void, Never>?
    private(set) var nextTimer: CGFloat?
    var currentTime: Double = 0.0
    private(set) var duration: Double = .greatestFiniteMagnitude
    private(set) var error: Error?
    var subtitles: String?
    private(set) var isPlaying: Bool = true
    private(set) var isLoading: Bool = true
    private(set) var isMaskShow: Bool = true
    private var isMaskLocked: Bool = false
    private var hideMaskTask: Task<Void, Never>?
    private(set) var subtitlesOptions: [AVMediaSelectionOption] = []
    private(set) var thumbnails: WebVTT?
    var window: NSWindow?
    private(set) var rate: Float = Defaults[.rate]
    private(set) var isMuted: Bool = Defaults[.isMuted]
    private(set) var volume: Float = Defaults[.volume]
    private var videoGravity: VideoGravity = Defaults[.videoGravity]
    private var ambientLight: Bool = Defaults[.ambientLight]
    private(set) var playerFullscreen: Bool = Defaults[.playerFullscreen]
    private var mediaControlButtonIsSeeking: Bool = Defaults[.mediaControlButtonIsSeeking]
    var isFocused = false
    var dismiss: DismissAction?

    func setupPlayer(seek: CMTime? = nil, isPlaying playing: Bool = true, subtitles: String? = nil) {
        guard let urls = movie.getClosestTo(quality: quality)?.compactMap(\.hls), !urls.isEmpty else { return }

        let player = CustomAVPlayer(urls: urls, subtitles: movie.subtitles)

        if let player, let currentItem = player.currentItem {
            let pipController = AVPictureInPictureController(playerLayer: playerLayer)

            setAmbientLight(ambientLight && videoGravity == .fit && !isPictureInPictureActive, avPlayerItem: currentItem)

            playerLayer.videoGravity = videoGravity.gravity

            nowPlayingInfoCenter.nowPlayingInfo = [:]

            routeDetector.isRouteDetectionEnabled = true

            if let thumbnails = movie.thumbnails {
                getMovieThumbnailsUseCase(path: thumbnails)
                    .receive(on: DispatchQueue.main)
                    .sink { _ in } receiveValue: { [weak self] thumbnails in
                        self?.thumbnails = thumbnails
                    }
                    .store(in: &subscriptions)
            }

            let timePublisher = player.periodicTimePublisher(forInterval: CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
                .removeDuplicates()
                .receive(on: DispatchQueue.main)
                .share()

            timePublisher
                .sink { [weak self] time in
                    guard let self else { return }

                    let currentTime = time.seconds

                    self.currentTime = currentTime

                    self.nowPlayingInfoCenter.nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
                    self.nowPlayingInfoCenter.nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = self.rate
                    self.nowPlayingInfoCenter.nowPlayingInfo?[MPNowPlayingInfoPropertyCurrentPlaybackDate] = currentItem.currentDate()
                    self.nowPlayingInfoCenter.nowPlayingInfo?[MPNowPlayingInfoPropertyDefaultPlaybackRate] = player.defaultRate

                    let targetTime = CMTime(seconds: time.seconds + 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))

                    if self.ambientLight, self.videoGravity == .fit, !self.isPictureInPictureActive {
                        if self.videoOutput.hasNewPixelBuffer(forItemTime: targetTime) {
                            if #available(macOS 26.0, *),
                               let pixelBuffer = self.videoOutput.pixelBufferAndDisplayTime(forItemTime: targetTime).pixelBuffer,
                               let cgImage = pixelBuffer.withUnsafeBuffer({ buffer in
                                   let ciImage = CIImage(cvPixelBuffer: buffer)

                                   let scaleTransform = CGAffineTransform(scaleX: 0.25, y: 0.25)

                                   let transformed = ciImage
                                       .transformed(by: scaleTransform, highQualityDownsample: false)
                                       .clampedToExtent()
                                       .cropped(to: ciImage.extent.applying(scaleTransform))

                                   return self.ciContext.createCGImage(transformed, from: transformed.extent)
                               })
                            {
                                if self.glowImage == nil {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        self.glowImage = Image(decorative: cgImage, scale: 1.0)
                                    }
                                } else {
                                    self.glowImage = Image(decorative: cgImage, scale: 1.0)
                                }
                            } else if let pixelBuffer = self.videoOutput.copyPixelBuffer(forItemTime: targetTime, itemTimeForDisplay: nil) {
                                let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

                                let scaleTransform = CGAffineTransform(scaleX: 0.25, y: 0.25)

                                let transformed = ciImage
                                    .transformed(by: scaleTransform, highQualityDownsample: false)
                                    .clampedToExtent()
                                    .cropped(to: ciImage.extent.applying(scaleTransform))

                                if let cgImage = self.ciContext.createCGImage(transformed, from: transformed.extent) {
                                    if self.glowImage == nil {
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            self.glowImage = Image(decorative: cgImage, scale: 1.0)
                                        }
                                    } else {
                                        self.glowImage = Image(decorative: cgImage, scale: 1.0)
                                    }
                                }
                            }
                        }
                    }

                    self.updateNextTimer()
                }
                .store(in: &subscriptions)

            timePublisher
                .throttle(for: .seconds(1), scheduler: DispatchQueue.main, latest: true)
                .sink { [weak self] time in
                    guard let self else { return }

                    let currentTime = time.seconds

                    MainActor.assumeIsolated {
                        let modelContext = self.modelContainer.mainContext

                        let voiceId = self.voiceActing.voiceId
                        let translatorId = self.voiceActing.translatorId
                        let seasonId = self.season?.seasonId
                        let episodeId = self.episode?.episodeId

                        let predicate = #Predicate<PlayerPosition> { position in
                            position.id == voiceId &&
                                position.acting == translatorId &&
                                position.season == seasonId &&
                                position.episode == episodeId
                        }

                        if let position = try? modelContext.fetch(FetchDescriptor<PlayerPosition>(predicate: predicate)).first {
                            position.position = currentTime
                        } else {
                            let position = PlayerPosition(
                                id: voiceId,
                                acting: translatorId,
                                season: seasonId,
                                episode: episodeId,
                                position: currentTime
                            )

                            modelContext.insert(position)
                        }
                    }
                }
                .store(in: &subscriptions)

            player.publisher(for: \.status)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] status in
                    guard let self else { return }

                    switch status {
                    case .readyToPlay:
                        self.isFocused = true

                        if Defaults[.isLoggedIn] {
                            self.saveWatchingStateUseCase(voiceActing: self.voiceActing, season: self.season, episode: self.episode)
                                .sink { _ in } receiveValue: { _ in }
                                .store(in: &self.subscriptions)
                        }

                        MainActor.assumeIsolated {
                            let modelContext = self.modelContainer.mainContext

                            let voiceId = self.voiceActing.voiceId
                            let translatorId = self.voiceActing.translatorId
                            let seasonId = self.season?.seasonId
                            let episodeId = self.episode?.episodeId

                            let predicate = #Predicate<SelectPosition> { position in
                                position.id == voiceId
                            }

                            if let position = try? modelContext.fetch(FetchDescriptor<SelectPosition>(predicate: predicate)).first {
                                position.acting = translatorId
                                position.season = seasonId
                                position.episode = episodeId
                            } else {
                                let position = SelectPosition(
                                    id: voiceId,
                                    acting: translatorId,
                                    season: seasonId,
                                    episode: episodeId
                                )

                                modelContext.insert(position)
                            }
                        }

                        currentItem.asset.loadMediaSelectionGroup(for: .legible) { [weak self] mediaSelectionGroup, _ in
                            guard let self else { return }

                            if let mediaSelectionGroup {
                                currentItem.select(mediaSelectionGroup.options.filter { $0.extendedLanguageTag != nil }.first(where: { $0.extendedLanguageTag == subtitles }), in: mediaSelectionGroup)

                                withAnimation(.easeInOut(duration: 0.15)) {
                                    self.subtitlesOptions = mediaSelectionGroup.options.filter { $0.extendedLanguageTag != nil }
                                } completion: {
                                    self.subtitles = subtitles
                                }
                            }
                        }

                        self.remoteCommandCenter.previousTrackCommand.removeTarget(nil)
                        self.remoteCommandCenter.nextTrackCommand.removeTarget(nil)

                        if self.isSeries, !self.mediaControlButtonIsSeeking {
                            self.remoteCommandCenter.previousTrackCommand.addTarget { [weak self] _ in
                                guard let self else { return .commandFailed }

                                self.prevTrack()

                                return .success
                            }

                            self.remoteCommandCenter.nextTrackCommand.addTarget { [weak self] _ in
                                guard let self else { return .commandFailed }

                                self.nextTrack()

                                return .success
                            }

                            self.remoteCommandCenter.previousTrackCommand.isEnabled = self.hasPrevoiusEpisode
                            self.remoteCommandCenter.nextTrackCommand.isEnabled = self.hasNextEpisode
                        } else if self.mediaControlButtonIsSeeking {
                            self.remoteCommandCenter.previousTrackCommand.addTarget { [weak self] _ in
                                guard let self else { return .commandFailed }

                                player.seek(to: CMTime(seconds: max(self.currentTime - 10.0, 0.0), preferredTimescale: CMTimeScale(NSEC_PER_SEC)), toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] complete in
                                    guard let self else { return }

                                    if self.isPlaying, complete {
                                        player.playImmediately(atRate: self.rate)
                                    }
                                }

                                self.currentTime = max(self.currentTime - 10.0, 0.0)

                                return .success
                            }

                            self.remoteCommandCenter.nextTrackCommand.addTarget { [weak self] _ in
                                guard let self else { return .commandFailed }

                                player.seek(to: CMTime(seconds: min(self.currentTime + 10.0, self.duration), preferredTimescale: CMTimeScale(NSEC_PER_SEC)), toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] complete in
                                    guard let self else { return }

                                    if self.isPlaying, complete {
                                        player.playImmediately(atRate: self.rate)
                                    }
                                }

                                self.currentTime = min(self.currentTime + 10.0, self.duration)

                                return .success
                            }

                            self.remoteCommandCenter.previousTrackCommand.isEnabled = true
                            self.remoteCommandCenter.nextTrackCommand.isEnabled = true
                        }

                        self.updateNextTimer()

                        if let seek {
                            player.seek(to: seek, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
                                guard let self else { return }

                                if playing {
                                    player.playImmediately(atRate: self.rate)
                                }
                            }
                        } else {
                            MainActor.assumeIsolated {
                                let modelContext = self.modelContainer.mainContext

                                let voiceId = self.voiceActing.voiceId
                                let translatorId = self.voiceActing.translatorId
                                let seasonId = self.season?.seasonId
                                let episodeId = self.episode?.episodeId

                                let predicate = #Predicate<PlayerPosition> { position in
                                    position.id == voiceId &&
                                        position.acting == translatorId &&
                                        position.season == seasonId &&
                                        position.episode == episodeId
                                }

                                if let position = try? modelContext.fetch(FetchDescriptor<PlayerPosition>(predicate: predicate)).first {
                                    player.seek(to: CMTime(seconds: position.position, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] complete in
                                        guard let self else { return }

                                        if playing, complete {
                                            player.playImmediately(atRate: rate)
                                        }
                                    }
                                } else if playing {
                                    player.playImmediately(atRate: self.rate)
                                }
                            }
                        }
                    default:
                        break
                    }
                }
                .store(in: &subscriptions)

            player.publisher(for: \.timeControlStatus)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] status in
                    guard let self else { return }

                    withAnimation(.easeInOut(duration: 0.15)) {
                        switch status {
                        case .playing:
                            self.isPlaying = true
                            self.isLoading = false

                            self.nowPlayingInfoCenter.playbackState = .playing
                        case .paused:
                            self.isPlaying = false
                            self.isLoading = false

                            self.nowPlayingInfoCenter.playbackState = .paused
                        case .waitingToPlayAtSpecifiedRate:
                            self.isPlaying = false
                            self.isLoading = true

                            self.nowPlayingInfoCenter.playbackState = .paused
                        default:
                            self.isPlaying = false
                            self.isLoading = true

                            self.nowPlayingInfoCenter.playbackState = .paused
                        }
                    }

                    self.showCursor()

                    self.setMask(!self.isPictureInPictureActive)

                    self.updateNextTimer()
                }
                .store(in: &subscriptions)

            player.publisher(for: \.isMuted)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] isMuted in
                    guard let self else { return }

                    Defaults[.isMuted] = isMuted

                    self.showCursor()

                    self.setMask(!self.isPictureInPictureActive)

                    self.updateNextTimer()
                }
                .store(in: &subscriptions)

            player.publisher(for: \.volume)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] volume in
                    guard let self else { return }

                    Defaults[.volume] = volume

                    player.isMuted = Defaults[.isMuted]

                    self.showCursor()

                    self.setMask(!self.isPictureInPictureActive)

                    self.updateNextTimer()
                }
                .store(in: &subscriptions)

            player.publisher(for: \.error)
                .compactMap(\.self)
                .handleError()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] error in
                    guard let self else { return }

                    self.resetPlayer { [weak self] in
                        guard let self else { return }

                        withAnimation(.easeInOut) {
                            self.error = error
                        }
                    }
                }
                .store(in: &subscriptions)

            currentItem.publisher(for: \.duration)
                .compactMap(\.self)
                .filter { $0.isValid && !$0.isIndefinite && !$0.isNegativeInfinity && !$0.isPositiveInfinity && $0.seconds > 0 }
                .receive(on: DispatchQueue.main)
                .sink { [weak self] duration in
                    guard let self else { return }

                    self.duration = duration.seconds

                    self.nowPlayingInfoCenter.nowPlayingInfo?[MPMediaItemPropertyPlaybackDuration] = duration.seconds

                    self.updateNextTimer()
                }
                .store(in: &subscriptions)

            currentItem.publisher(for: \.loadedTimeRanges)
                .compactMap { $0 as? [CMTimeRange] }
                .receive(on: DispatchQueue.main)
                .assign(to: \.loadedTimeRanges, on: self)
                .store(in: &subscriptions)

            currentItem.publisher(for: \.error)
                .compactMap(\.self)
                .handleError()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] error in
                    guard let self else { return }

                    self.resetPlayer { [weak self] in
                        guard let self else { return }

                        withAnimation(.easeInOut) {
                            self.error = error
                        }
                    }
                }
                .store(in: &subscriptions)

            NotificationCenter.default.publisher(for: AVPlayerItem.didPlayToEndTimeNotification, object: currentItem)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    guard let self else { return }

                    player.seek(to: CMTime(seconds: 0, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
                        guard let self else { return }

                        if self.isPictureInPictureActive, let pipController = self.pipController {
                            pipController.stopPictureInPicture()
                        } else if self.timer != -1, self.hasNextEpisode {
                            self.nextTrack()
                        }

                        self.updateNextTimer()
                    }
                }
                .store(in: &subscriptions)

            NotificationCenter.default.publisher(for: AVPlayerItem.failedToPlayToEndTimeNotification, object: currentItem)
                .compactMap { $0.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error }
                .handleError()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] error in
                    guard let self else { return }

                    self.resetPlayer { [weak self] in
                        guard let self else { return }

                        withAnimation(.easeInOut) {
                            self.error = error
                        }
                    }
                }
                .store(in: &subscriptions)

            withAnimation(.easeInOut(duration: 0.15)) {
                self.routesDetected = self.routeDetector.multipleRoutesDetected
            }

            NotificationCenter.default.publisher(for: .AVRouteDetectorMultipleRoutesDetectedDidChange)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    guard let self else { return }

                    withAnimation(.easeInOut(duration: 0.15)) {
                        self.routesDetected = self.routeDetector.multipleRoutesDetected
                    }
                }
                .store(in: &subscriptions)

            if let pipController {
                pipController.publisher(for: \.isPictureInPictureActive)
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] isPictureInPictureActive in
                        guard let self else { return }

                        withAnimation(.easeInOut) {
                            self.isPictureInPictureActive = isPictureInPictureActive
                        }

                        self.showCursor()

                        self.setMask(!isPictureInPictureActive)

                        self.updateNextTimer()

                        if let window = self.window,!isPictureInPictureActive {
                            window.makeKeyAndOrderFront(nil)
                        }

                        self.setAmbientLight(self.ambientLight && self.videoGravity == .fit && !isPictureInPictureActive, avPlayerItem: currentItem)

//                        if let window = self.window {
//                            if isPictureInPictureActive {
//                                window.miniaturize(nil)
//                            } else {
//                                window.deminiaturize(nil)
//                            }
//                        }
                    }
                    .store(in: &subscriptions)

                pipController.publisher(for: \.isPictureInPicturePossible)
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] isPictureInPicturePossible in
                        guard let self else { return }

                        withAnimation(.easeInOut(duration: 0.15)) {
                            self.isPictureInPicturePossible = isPictureInPicturePossible
                        }
                    }
                    .store(in: &subscriptions)
            }

            Defaults.publisher(.rate)
                .receive(on: DispatchQueue.main)
                .map(\.newValue)
                .sink { [weak self] rate in
                    guard let self else { return }

                    self.rate = rate

                    self.nowPlayingInfoCenter.nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = rate

                    if self.isPlaying {
                        self.playerLayer.player?.playImmediately(atRate: rate)
                    }
                }
                .store(in: &subscriptions)

            Defaults.publisher(.isMuted)
                .receive(on: DispatchQueue.main)
                .map(\.newValue)
                .sink { [weak self] isMuted in
                    guard let self else { return }

                    withAnimation(.easeInOut(duration: 0.15)) {
                        self.isMuted = isMuted
                    }
                }
                .store(in: &subscriptions)

            Defaults.publisher(.volume)
                .receive(on: DispatchQueue.main)
                .map(\.newValue)
                .sink { [weak self] volume in
                    guard let self else { return }

                    withAnimation(.easeInOut(duration: 0.15)) {
                        self.volume = volume
                    }
                }
                .store(in: &subscriptions)

            Defaults.publisher(.spatialAudio)
                .receive(on: DispatchQueue.main)
                .map(\.newValue)
                .sink { spatialAudio in
                    currentItem.allowedAudioSpatializationFormats = spatialAudio.format
                }
                .store(in: &subscriptions)

            Defaults.publisher(.playerFullscreen)
                .receive(on: DispatchQueue.main)
                .map(\.newValue)
                .assign(to: \.playerFullscreen, on: self)
                .store(in: &subscriptions)

            Defaults.publisher(.videoGravity)
                .receive(on: DispatchQueue.main)
                .map(\.newValue)
                .sink { [weak self] videoGravity in
                    guard let self else { return }

                    self.videoGravity = videoGravity

                    self.setAmbientLight(self.ambientLight && videoGravity == .fit && !self.isPictureInPictureActive, avPlayerItem: currentItem)

                    self.playerLayer.videoGravity = videoGravity.gravity
                }
                .store(in: &subscriptions)

            Defaults.publisher(.ambientLight)
                .receive(on: DispatchQueue.main)
                .map(\.newValue)
                .sink { [weak self] ambientLight in
                    guard let self else { return }

                    self.ambientLight = ambientLight

                    self.setAmbientLight(ambientLight && self.videoGravity == .fit && !self.isPictureInPictureActive, avPlayerItem: currentItem)
                }
                .store(in: &subscriptions)

            Defaults.publisher(.mediaControlButtonIsSeeking)
                .receive(on: DispatchQueue.main)
                .map(\.newValue)
                .sink { [weak self] mediaControlButtonIsSeeking in
                    guard let self else { return }

                    self.mediaControlButtonIsSeeking = mediaControlButtonIsSeeking

                    self.remoteCommandCenter.previousTrackCommand.removeTarget(nil)
                    self.remoteCommandCenter.nextTrackCommand.removeTarget(nil)

                    if self.isSeries, player.status == .readyToPlay, !mediaControlButtonIsSeeking {
                        self.remoteCommandCenter.previousTrackCommand.addTarget { [weak self] _ in
                            guard let self else { return .commandFailed }

                            self.prevTrack()

                            return .success
                        }

                        self.remoteCommandCenter.nextTrackCommand.addTarget { [weak self] _ in
                            guard let self else { return .commandFailed }

                            self.nextTrack()

                            return .success
                        }

                        self.remoteCommandCenter.previousTrackCommand.isEnabled = self.hasPrevoiusEpisode
                        self.remoteCommandCenter.nextTrackCommand.isEnabled = self.hasNextEpisode
                    } else if player.status == .readyToPlay, mediaControlButtonIsSeeking {
                        self.remoteCommandCenter.previousTrackCommand.addTarget { [weak self] _ in
                            guard let self else { return .commandFailed }

                            player.seek(to: CMTime(seconds: max(self.currentTime - 10.0, 0.0), preferredTimescale: CMTimeScale(NSEC_PER_SEC)), toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] complete in
                                guard let self else { return }

                                if self.isPlaying, complete {
                                    player.playImmediately(atRate: self.rate)
                                }
                            }

                            self.currentTime = max(self.currentTime - 10.0, 0.0)

                            return .success
                        }

                        self.remoteCommandCenter.nextTrackCommand.addTarget { [weak self] _ in
                            guard let self else { return .commandFailed }

                            player.seek(to: CMTime(seconds: min(self.currentTime + 10.0, self.duration), preferredTimescale: CMTimeScale(NSEC_PER_SEC)), toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] complete in
                                guard let self else { return }

                                if self.isPlaying, complete {
                                    player.playImmediately(atRate: self.rate)
                                }
                            }

                            self.currentTime = min(self.currentTime + 10.0, self.duration)

                            return .success
                        }

                        self.remoteCommandCenter.previousTrackCommand.isEnabled = true
                        self.remoteCommandCenter.nextTrackCommand.isEnabled = true
                    }
                }
                .store(in: &subscriptions)

            nowPlayingInfoCenter.nowPlayingInfo?[MPNowPlayingInfoPropertyAssetURL] = urls.first
            nowPlayingInfoCenter.nowPlayingInfo?[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.video.rawValue
            nowPlayingInfoCenter.nowPlayingInfo?[MPNowPlayingInfoPropertyIsLiveStream] = false
            nowPlayingInfoCenter.nowPlayingInfo?[MPMediaItemPropertyTitle] = name
            nowPlayingInfoCenter.nowPlayingInfo?[MPMediaItemPropertyAlbumTitle] = voiceActing.name

            if let season, let episode {
                nowPlayingInfoCenter.nowPlayingInfo?[MPMediaItemPropertyArtist] = "Season \(season.name) Episode \(episode.name)"
            }

            if let url = URL(string: poster) {
                KingfisherManager.shared.retrieveImage(with: url) { [weak self] result in
                    if case let .success(value) = result {
                        self?.nowPlayingInfoCenter.nowPlayingInfo?[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: value.image.size) { _ in value.image }
                    }
                }
            }

            remoteCommandCenter.playCommand.addTarget { [weak self] _ in
                guard let self else { return .commandFailed }

                player.playImmediately(atRate: self.rate)

                return .success
            }

            remoteCommandCenter.pauseCommand.addTarget { _ in
                player.pause()

                return .success
            }

            remoteCommandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
                guard let self else { return .commandFailed }

                if self.isPlaying {
                    player.pause()
                } else {
                    player.playImmediately(atRate: self.rate)
                }

                return .success
            }

            remoteCommandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
                guard let self,
                      let effectiveEvent = event as? MPChangePlaybackPositionCommandEvent
                else {
                    return .commandFailed
                }

                player.seek(to: CMTime(seconds: effectiveEvent.positionTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] success in
                    guard let self else { return }

                    if success {
                        self.updateNextTimer()
                    }
                }

                return .success
            }

            remoteCommandCenter.changePlaybackRateCommand.addTarget { [weak self] event in
                guard let self,
                      let effectiveEvent = event as? MPChangePlaybackRateCommandEvent
                else {
                    return .commandFailed
                }

                Defaults[.rate] = effectiveEvent.playbackRate
                self.nowPlayingInfoCenter.nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = effectiveEvent.playbackRate

                if self.isPlaying {
                    player.playImmediately(atRate: effectiveEvent.playbackRate)
                }

                return .success
            }

            remoteCommandCenter.skipBackwardCommand.addTarget { [weak self] event in
                guard let self,
                      let event = event as? MPSkipIntervalCommandEvent
                else {
                    return .commandFailed
                }

                player.seek(to: CMTime(seconds: max(self.currentTime - event.interval, 0.0), preferredTimescale: CMTimeScale(NSEC_PER_SEC)), toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] complete in
                    guard let self else { return }

                    if self.isPlaying, complete {
                        player.playImmediately(atRate: self.rate)
                    }
                }

                self.currentTime = max(self.currentTime - event.interval, 0.0)

                return .success
            }

            remoteCommandCenter.skipForwardCommand.addTarget { [weak self] event in
                guard let self,
                      let event = event as? MPSkipIntervalCommandEvent
                else {
                    return .commandFailed
                }

                player.seek(to: CMTime(seconds: min(self.currentTime + event.interval, self.duration), preferredTimescale: CMTimeScale(NSEC_PER_SEC)), toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] complete in
                    guard let self else { return }

                    if self.isPlaying, complete {
                        player.playImmediately(atRate: self.rate)
                    }
                }

                self.currentTime = min(self.currentTime + event.interval, self.duration)

                return .success
            }

            remoteCommandCenter.pauseCommand.isEnabled = true
            remoteCommandCenter.playCommand.isEnabled = true
            remoteCommandCenter.togglePlayPauseCommand.isEnabled = true
            remoteCommandCenter.changePlaybackPositionCommand.isEnabled = true
            remoteCommandCenter.changePlaybackRateCommand.isEnabled = true
            remoteCommandCenter.changePlaybackRateCommand.supportedPlaybackRates = rates.map { NSNumber(value: $0) }
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

            player.volume = volume
            player.isMuted = isMuted

            withAnimation(.easeInOut) {
                playerLayer.player = player
                self.pipController = pipController
            }
        }
    }

    func resetPlayer(completion: (() -> Void)? = nil) {
        subscriptions.flush()

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

        timerTask?.cancel()
        hideMaskTask?.cancel()

        thumbnails = nil

        routeDetector.isRouteDetectionEnabled = false

        if let outputs = playerLayer.player?.currentItem?.outputs {
            for output in outputs {
                playerLayer.player?.currentItem?.remove(output)
            }
        }

        playerLayer.player?.pause()
        playerLayer.player?.replaceCurrentItem(with: nil)

        withAnimation(.easeInOut) {
            playerLayer.player = nil
            pipController = nil
            glowImage = nil
            error = nil
            nextTimer = nil
            subtitlesOptions = []
            isLoading = true
        } completion: {
            completion?()
        }

        duration = .greatestFiniteMagnitude
        currentTime = 0.0
    }

    func selectSubtitles(_ language: String?) {
        guard let player = playerLayer.player,
              let currentItem = player.currentItem
        else {
            return
        }

        Task { @MainActor [weak self] in
            guard let self else { return }

            if let mediaSelectionGroup = try? await currentItem.asset.loadMediaSelectionGroup(for: .legible) {
                currentItem.select(mediaSelectionGroup.options.filter { $0.extendedLanguageTag != nil }.first(where: { $0.extendedLanguageTag == language }), in: mediaSelectionGroup)

                let modelContext = modelContainer.mainContext

                let voiceId = self.voiceActing.voiceId
                let translatorId = self.voiceActing.translatorId
                let seasonId = self.season?.seasonId
                let episodeId = self.episode?.episodeId

                let predicate = #Predicate<SelectPosition> { position in
                    position.id == voiceId
                }

                if let position = try? modelContext.fetch(FetchDescriptor<SelectPosition>(predicate: predicate)).first {
                    position.subtitles = language
                } else {
                    let position = SelectPosition(
                        id: voiceId,
                        acting: translatorId,
                        season: seasonId,
                        episode: episodeId,
                        subtitles: language
                    )

                    modelContext.insert(position)
                }
            }
        }
    }

    func resetTimer() {
        timerTask?.cancel()

        updateNextTimer()

        guard let timer,
              timer > 0,
              isPlaying
        else {
            return
        }

        timerTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(timer))

            guard !Task.isCancelled,
                  let self,
                  let player = self.playerLayer.player,
                  player.status == .readyToPlay
            else {
                return
            }

            player.pause()
        }
    }

    func setMask(_ newValue: Bool) {
        guard !isMaskLocked else { return }

        withAnimation(.easeInOut) {
            isMaskShow = newValue
        }

        hideMaskTask?.cancel()

        guard newValue, !isLoading, isPlaying else { return }

        hideMaskTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(3))

            guard !Task.isCancelled, let self else { return }

            self.showCursor(false)

            self.setMask(false)
        }
    }

    func lockMask(_ newValue: Bool) {
        isMaskLocked = true

        withAnimation(.easeInOut) {
            isMaskShow = newValue
        }

        hideMaskTask?.cancel()
    }

    func unlockMask(_ newValue: Bool) {
        isMaskLocked = false

        setMask(newValue)
    }

    func updateNextTimer() {
        if (duration - currentTime) / 60 > 0, (duration - currentTime) / 60 <= 1, let seasons, let season, let episode, seasons.element(after: season) != nil || season.episodes.element(after: episode) != nil, timer != -1, !isPictureInPictureActive {
            withAnimation(.easeInOut) {
                nextTimer = min((duration - currentTime) / 60, 1.0)
            }
        } else if nextTimer != nil {
            withAnimation(.easeInOut) {
                nextTimer = nil
            }
        }
    }

    func showCursor(_ isShowed: Bool = true) {
        if isShowed {
            NSCursor.unhide()
        } else {
            NSCursor.setHiddenUntilMouseMoves(true)
        }
    }

    func prevTrack() {
        guard let seasons, let season, let episode else { return }

        if let prevEpisode = season.episodes.element(before: episode) {
            withAnimation(.easeInOut(duration: 0.15)) {
                isLoading = true
            }

            resetPlayer { [weak self] in
                guard let self else { return }

                self.getMovieVideoUseCase(voiceActing: self.voiceActing, season: season, episode: prevEpisode, favs: self.favs)
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] completion in
                        guard let self,
                              case let .failure(error) = completion
                        else {
                            return
                        }

                        withAnimation(.easeInOut) {
                            self.error = error
                        }
                    } receiveValue: { [weak self] movie in
                        guard let self else { return }

                        if movie.needPremium {
                            self.dismiss?()

                            AppState.shared.isPremiumPresented = true
                        } else {
                            self.movie = movie
                            self.episode = prevEpisode

                            self.setupPlayer(subtitles: self.subtitles)
                        }
                    }
                    .store(in: &self.subscriptions)
            }
        } else if let prevSeason = seasons.element(before: season), let prevEpisode = prevSeason.episodes.last {
            withAnimation(.easeInOut(duration: 0.15)) {
                isLoading = true
            }

            resetPlayer { [weak self] in
                guard let self else { return }

                self.getMovieVideoUseCase(voiceActing: self.voiceActing, season: prevSeason, episode: prevEpisode, favs: self.favs)
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] completion in
                        guard let self,
                              case let .failure(error) = completion
                        else {
                            return
                        }

                        withAnimation(.easeInOut) {
                            self.error = error
                        }
                    } receiveValue: { [weak self] movie in
                        guard let self else { return }

                        if movie.needPremium {
                            self.dismiss?()

                            AppState.shared.isPremiumPresented = true
                        } else {
                            self.movie = movie
                            self.season = prevSeason
                            self.episode = prevEpisode

                            self.setupPlayer(subtitles: self.subtitles)
                        }
                    }
                    .store(in: &self.subscriptions)
            }
        }
    }

    func nextTrack() {
        guard let seasons, let season, let episode else { return }

        if let nextEpisode = season.episodes.element(after: episode) {
            withAnimation(.easeInOut(duration: 0.15)) {
                isLoading = true
            }

            resetPlayer { [weak self] in
                guard let self else { return }

                self.getMovieVideoUseCase(voiceActing: self.voiceActing, season: season, episode: nextEpisode, favs: self.favs)
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] completion in
                        guard let self,
                              case let .failure(error) = completion
                        else {
                            return
                        }

                        withAnimation(.easeInOut) {
                            self.error = error
                        }
                    } receiveValue: { [weak self] movie in
                        guard let self else { return }

                        if movie.needPremium {
                            self.dismiss?()

                            AppState.shared.isPremiumPresented = true
                        } else {
                            self.movie = movie
                            self.episode = nextEpisode

                            self.setupPlayer(subtitles: self.subtitles)
                        }
                    }
                    .store(in: &self.subscriptions)
            }
        } else if let nextSeason = seasons.element(after: season), let nextEpisode = nextSeason.episodes.first {
            withAnimation(.easeInOut(duration: 0.15)) {
                isLoading = true
            }

            resetPlayer { [weak self] in
                guard let self else { return }

                self.getMovieVideoUseCase(voiceActing: self.voiceActing, season: nextSeason, episode: nextEpisode, favs: self.favs)
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] completion in
                        guard let self,
                              case let .failure(error) = completion
                        else {
                            return
                        }

                        withAnimation(.easeInOut) {
                            self.error = error
                        }
                    } receiveValue: { [weak self] movie in
                        guard let self else { return }

                        if movie.needPremium {
                            self.dismiss?()

                            AppState.shared.isPremiumPresented = true
                        } else {
                            self.movie = movie
                            self.season = nextSeason
                            self.episode = nextEpisode

                            self.setupPlayer(subtitles: self.subtitles)
                        }
                    }
                    .store(in: &self.subscriptions)
            }
        }
    }

    private func setAmbientLight(_ enable: Bool = true, avPlayerItem: AVPlayerItem) {
        for output in avPlayerItem.outputs {
            avPlayerItem.remove(output)
        }

        if enable {
            avPlayerItem.add(videoOutput)
        } else {
            withAnimation(.easeInOut(duration: 0.15)) {
                self.glowImage = nil
            }
        }
    }
}
