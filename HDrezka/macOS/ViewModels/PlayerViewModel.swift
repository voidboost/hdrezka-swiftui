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

    @ObservationIgnored let poster: String
    @ObservationIgnored let name: String
    @ObservationIgnored let favs: String
    @ObservationIgnored let voiceActing: MovieVoiceActing

    @ObservationIgnored let hideMainWindow: Bool

    @ObservationIgnored let times: [Int]

    var seasons: [MovieSeason]?
    var season: MovieSeason?
    var episode: MovieEpisode?
    var movie: MovieVideo
    var quality: String

    init(poster: String, name: String, favs: String, voiceActing: MovieVoiceActing, hideMainWindow: Bool, seasons: [MovieSeason]?, season: MovieSeason?, episode: MovieEpisode?, movie: MovieVideo, quality: String) {
        self.poster = poster
        self.name = name
        self.favs = favs
        self.voiceActing = voiceActing
        self.hideMainWindow = hideMainWindow
        self.seasons = seasons
        self.season = season
        self.episode = episode
        self.movie = movie
        self.quality = quality

        times = seasons != nil && season != nil && episode != nil ? [900, 1800, 2700, 3600, -1] : [900, 1800, 2700, 3600]
    }

    deinit {
        subscriptions.flush()
        timerWork?.cancel()
        delayHide?.cancel()
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

    var pipController: AVPictureInPictureController?
    var isPictureInPictureActive: Bool = false
    var isPictureInPicturePossible: Bool = false
    var videoGravity: AVLayerVideoGravity = .resizeAspect
    var loadedTimeRanges: [CMTimeRange] = []
    var timeObserverToken: Any?
    var timer: Int?
    var timerWork: DispatchWorkItem?
    var nextTimer: CGFloat?
    var currentTime: Double = 0.0
    var duration: Double = .greatestFiniteMagnitude
    var error: Error?
    var subtitles: String?
    var isPlaying: Bool = true
    var isLoading: Bool = true
    var isMaskShow: Bool = true
    var delayHide: DispatchWorkItem?
    var subtitlesOptions: [AVMediaSelectionOption] = []
    var thumbnails: WebVTT?
    var window: NSWindow?
    var rate: Float = Defaults[.rate]
    var isMuted: Bool = Defaults[.isMuted]
    var volume: Float = Defaults[.volume]
    var spatialAudio: SpatialAudio = Defaults[.spatialAudio]
    var playerFullscreen: Bool = Defaults[.playerFullscreen]
    var isFocused = false
    var dismiss: DismissAction?

    func setupPlayer(seek: CMTime? = nil, isPlaying playing: Bool = true, subtitles: String? = nil) {
        guard let urls = movie.getClosestTo(quality: quality)?.compactMap(\.hls), !urls.isEmpty else { return }

        let player = CustomAVPlayer(urls: urls, subtitles: movie.subtitles)

        if let player, let currentItem = player.currentItem {
            let pipController = AVPictureInPictureController(playerLayer: playerLayer)

            playerLayer.videoGravity = videoGravity

            nowPlayingInfoCenter.nowPlayingInfo = [:]

            if let thumbnails = movie.thumbnails {
                getMovieThumbnailsUseCase(path: thumbnails)
                    .receive(on: DispatchQueue.main)
                    .sink { _ in } receiveValue: { thumbnails in
                        self.thumbnails = thumbnails
                    }
                    .store(in: &subscriptions)
            }

            timeObserverToken = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: .main) { time in
                let currentTime = time.seconds

                self.currentTime = currentTime

                self.nowPlayingInfoCenter.nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
                self.nowPlayingInfoCenter.nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = self.rate
                self.nowPlayingInfoCenter.nowPlayingInfo?[MPNowPlayingInfoPropertyCurrentPlaybackDate] = currentItem.currentDate()
                self.nowPlayingInfoCenter.nowPlayingInfo?[MPNowPlayingInfoPropertyDefaultPlaybackRate] = player.defaultRate

                Task { @MainActor [weak self] in
                    guard let self else { return }

                    let modelContext = modelContainer.mainContext

                    if let position = try? modelContext.fetch(FetchDescriptor<PlayerPosition>(predicate: nil)).first(where: { position in
                        position.id == self.voiceActing.voiceId &&
                            position.acting == self.voiceActing.translatorId &&
                            position.season == self.season?.seasonId &&
                            position.episode == self.episode?.episodeId
                    }) {
                        position.position = currentTime
                    } else {
                        let position = PlayerPosition(
                            id: voiceActing.voiceId,
                            acting: voiceActing.translatorId,
                            season: season?.seasonId,
                            episode: episode?.episodeId,
                            position: currentTime,
                        )

                        modelContext.insert(position)
                    }
                }

                self.updateNextTimer()
            }

            player.publisher(for: \.status)
                .receive(on: DispatchQueue.main)
                .sink { status in
                    switch status {
                    case .readyToPlay:
                        self.isFocused = true

                        if Defaults[.isLoggedIn] {
                            self.saveWatchingStateUseCase(voiceActing: self.voiceActing, season: self.season, episode: self.episode)
                                .sink { _ in } receiveValue: { _ in }
                                .store(in: &self.subscriptions)
                        }

                        Task { @MainActor [weak self] in
                            guard let self else { return }

                            let modelContext = modelContainer.mainContext

                            if let position = try? modelContext.fetch(FetchDescriptor<SelectPosition>(predicate: nil)).first(where: { position in
                                position.id == self.voiceActing.voiceId
                            }) {
                                position.acting = voiceActing.translatorId
                                position.season = season?.seasonId
                                position.episode = episode?.episodeId
                            } else {
                                let position = SelectPosition(
                                    id: voiceActing.voiceId,
                                    acting: voiceActing.translatorId,
                                    season: season?.seasonId,
                                    episode: episode?.episodeId,
                                )

                                modelContext.insert(position)
                            }
                        }

                        currentItem.asset.loadMediaSelectionGroup(for: .legible) { mediaSelectionGroup, _ in
                            if let mediaSelectionGroup {
                                currentItem.select(mediaSelectionGroup.options.filter { $0.extendedLanguageTag != nil }.first(where: { $0.extendedLanguageTag == subtitles }), in: mediaSelectionGroup)

                                withAnimation(.easeInOut(duration: 0.15)) {
                                    self.subtitlesOptions = mediaSelectionGroup.options.filter { $0.extendedLanguageTag != nil }
                                } completion: {
                                    self.subtitles = subtitles
                                }
                            }
                        }

                        if self.isSeries {
                            self.remoteCommandCenter.previousTrackCommand.addTarget { _ in
                                self.prevTrack()

                                return .success
                            }

                            self.remoteCommandCenter.nextTrackCommand.addTarget { _ in
                                self.nextTrack()

                                return .success
                            }

                            self.remoteCommandCenter.previousTrackCommand.isEnabled = self.hasPrevoiusEpisode
                            self.remoteCommandCenter.nextTrackCommand.isEnabled = self.hasNextEpisode
                        }

                        self.updateNextTimer()

                        if let seek {
                            player.seek(to: seek, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
                                if playing {
                                    player.playImmediately(atRate: self.rate)
                                }
                            }
                        } else {
                            Task { @MainActor [weak self] in
                                guard let self else { return }

                                let modelContext = modelContainer.mainContext

                                if let position = try? modelContext.fetch(FetchDescriptor<PlayerPosition>(predicate: nil)).first(where: { position in
                                    position.id == self.voiceActing.voiceId &&
                                        position.acting == self.voiceActing.translatorId &&
                                        position.season == self.season?.seasonId &&
                                        position.episode == self.episode?.episodeId
                                }) {
                                    player.seek(to: CMTime(seconds: position.position, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), toleranceBefore: .zero, toleranceAfter: .zero) { _ in
                                        if playing {
                                            player.playImmediately(atRate: self.rate)
                                        }
                                    }
                                } else if playing {
                                    player.playImmediately(atRate: rate)
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
                .sink { status in
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
                .sink { isMuted in
                    Defaults[.isMuted] = isMuted

                    self.showCursor()

                    self.setMask(!self.isPictureInPictureActive)

                    self.updateNextTimer()
                }
                .store(in: &subscriptions)

            player.publisher(for: \.volume)
                .receive(on: DispatchQueue.main)
                .sink { volume in
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
                .sink { error in
                    self.resetPlayer {
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
                .sink { duration in
                    self.duration = duration.seconds

                    self.nowPlayingInfoCenter.nowPlayingInfo?[MPMediaItemPropertyPlaybackDuration] = duration.seconds

                    self.updateNextTimer()
                }
                .store(in: &subscriptions)

            currentItem.publisher(for: \.loadedTimeRanges)
                .compactMap { $0 as? [CMTimeRange] }
                .receive(on: DispatchQueue.main)
                .sink { loadedTimeRanges in
                    self.loadedTimeRanges = loadedTimeRanges
                }
                .store(in: &subscriptions)

            currentItem.publisher(for: \.error)
                .compactMap(\.self)
                .handleError()
                .receive(on: DispatchQueue.main)
                .sink { error in
                    self.resetPlayer {
                        withAnimation(.easeInOut) {
                            self.error = error
                        }
                    }
                }
                .store(in: &subscriptions)

            NotificationCenter.default.publisher(for: AVPlayerItem.didPlayToEndTimeNotification, object: currentItem)
                .receive(on: DispatchQueue.main)
                .sink { _ in
                    player.seek(to: CMTime(seconds: 0, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), toleranceBefore: .zero, toleranceAfter: .zero) { _ in
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
                .sink { error in
                    self.resetPlayer {
                        withAnimation(.easeInOut) {
                            self.error = error
                        }
                    }
                }
                .store(in: &subscriptions)

            playerLayer.publisher(for: \.videoGravity)
                .receive(on: DispatchQueue.main)
                .sink { videoGravity in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        self.videoGravity = videoGravity
                    }
                }
                .store(in: &subscriptions)

            if let pipController {
                pipController.publisher(for: \.isPictureInPictureActive)
                    .receive(on: DispatchQueue.main)
                    .sink { isPictureInPictureActive in
                        withAnimation(.easeInOut) {
                            self.isPictureInPictureActive = isPictureInPictureActive
                        }

                        self.showCursor()

                        self.setMask(!isPictureInPictureActive)

                        self.updateNextTimer()

                        if let window = self.window,!isPictureInPictureActive {
                            window.makeKeyAndOrderFront(nil)
                        }

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
                    .sink { isPictureInPicturePossible in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            self.isPictureInPicturePossible = isPictureInPicturePossible
                        }
                    }
                    .store(in: &subscriptions)
            }

            Defaults.publisher(.rate)
                .receive(on: DispatchQueue.main)
                .map(\.newValue)
                .sink { rate in
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
                .sink { isMuted in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        self.isMuted = isMuted
                    }
                }
                .store(in: &subscriptions)

            Defaults.publisher(.volume)
                .receive(on: DispatchQueue.main)
                .map(\.newValue)
                .sink { volume in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        self.volume = volume
                    }
                }
                .store(in: &subscriptions)

            Defaults.publisher(.spatialAudio)
                .receive(on: DispatchQueue.main)
                .map(\.newValue)
                .sink { spatialAudio in
                    self.spatialAudio = spatialAudio
                }
                .store(in: &subscriptions)

            Defaults.publisher(.playerFullscreen)
                .receive(on: DispatchQueue.main)
                .map(\.newValue)
                .sink { playerFullscreen in
                    self.playerFullscreen = playerFullscreen
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

            remoteCommandCenter.playCommand.addTarget { _ in
                player.playImmediately(atRate: self.rate)

                return .success
            }

            remoteCommandCenter.pauseCommand.addTarget { _ in
                player.pause()

                return .success
            }

            remoteCommandCenter.togglePlayPauseCommand.addTarget { _ in
                if self.isPlaying {
                    player.pause()
                } else {
                    player.playImmediately(atRate: self.rate)
                }

                return .success
            }

            remoteCommandCenter.changePlaybackPositionCommand.addTarget { event in
                guard let effectiveEvent = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }

                player.seek(to: CMTime(seconds: effectiveEvent.positionTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), toleranceBefore: .zero, toleranceAfter: .zero) { success in
                    if success {
                        self.updateNextTimer()
                    }
                }

                return .success
            }

            remoteCommandCenter.changePlaybackRateCommand.addTarget { event in
                guard let effectiveEvent = event as? MPChangePlaybackRateCommandEvent else { return .commandFailed }

                Defaults[.rate] = effectiveEvent.playbackRate
                self.nowPlayingInfoCenter.nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = effectiveEvent.playbackRate

                if self.isPlaying {
                    player.playImmediately(atRate: effectiveEvent.playbackRate)
                }

                return .success
            }

            remoteCommandCenter.pauseCommand.isEnabled = true
            remoteCommandCenter.playCommand.isEnabled = true
            remoteCommandCenter.togglePlayPauseCommand.isEnabled = true
            remoteCommandCenter.changePlaybackPositionCommand.isEnabled = true
            remoteCommandCenter.changePlaybackRateCommand.isEnabled = true
            remoteCommandCenter.changePlaybackRateCommand.supportedPlaybackRates = rates.map { NSNumber(value: $0) }

            remoteCommandCenter.previousTrackCommand.isEnabled = false
            remoteCommandCenter.nextTrackCommand.isEnabled = false
            remoteCommandCenter.stopCommand.isEnabled = false
            remoteCommandCenter.changeRepeatModeCommand.isEnabled = false
            remoteCommandCenter.enableLanguageOptionCommand.isEnabled = false
            remoteCommandCenter.changeShuffleModeCommand.isEnabled = false
            remoteCommandCenter.skipForwardCommand.isEnabled = false
            remoteCommandCenter.skipBackwardCommand.isEnabled = false
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
        if let timeObserverToken {
            playerLayer.player?.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }

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

        timerWork?.cancel()
        delayHide?.cancel()

        thumbnails = nil

        playerLayer.player?.pause()
        playerLayer.player?.replaceCurrentItem(with: nil)

        withAnimation(.easeInOut) {
            playerLayer.player = nil
            pipController = nil
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

        currentItem.asset.loadMediaSelectionGroup(for: .legible) { mediaSelectionGroup, _ in
            if let mediaSelectionGroup {
                currentItem.select(mediaSelectionGroup.options.filter { $0.extendedLanguageTag != nil }.first(where: { $0.extendedLanguageTag == language }), in: mediaSelectionGroup)

                Task { @MainActor [weak self] in
                    guard let self else { return }

                    let modelContext = modelContainer.mainContext

                    if let position = try? modelContext.fetch(FetchDescriptor<SelectPosition>(predicate: nil)).first(where: { position in
                        position.id == self.voiceActing.voiceId
                    }) {
                        position.subtitles = language
                    } else {
                        let position = SelectPosition(
                            id: voiceActing.voiceId,
                            acting: voiceActing.translatorId,
                            season: season?.seasonId,
                            episode: episode?.episodeId,
                            subtitles: language,
                        )

                        modelContext.insert(position)
                    }
                }
            }
        }
    }

    func resetTimer() {
        timerWork?.cancel()

        updateNextTimer()

        guard let timer,
              timer > 0,
              isPlaying
        else {
            return
        }

        timerWork = DispatchWorkItem {
            guard let player = self.playerLayer.player,
                  player.status == .readyToPlay
            else {
                return
            }

            player.pause()
        }

        if let timerWork {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(timer), execute: timerWork)
        }
    }

    func setMask(_ newValue: Bool, force: Bool = false) {
        withAnimation(.easeInOut) {
            isMaskShow = newValue
        }

        delayHide?.cancel()

        if newValue, !isLoading, isPlaying, !force {
            delayHide = DispatchWorkItem {
                self.showCursor(false)

                self.setMask(false)
            }

            if let delayHide {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: delayHide)
            }
        }
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

            resetPlayer {
                self.getMovieVideoUseCase(voiceActing: self.voiceActing, season: season, episode: prevEpisode, favs: self.favs)
                    .receive(on: DispatchQueue.main)
                    .sink { completion in
                        guard case let .failure(error) = completion else { return }

                        withAnimation(.easeInOut) {
                            self.error = error
                        }
                    } receiveValue: { movie in
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

            resetPlayer {
                self.getMovieVideoUseCase(voiceActing: self.voiceActing, season: prevSeason, episode: prevEpisode, favs: self.favs)
                    .receive(on: DispatchQueue.main)
                    .sink { completion in
                        guard case let .failure(error) = completion else { return }

                        withAnimation(.easeInOut) {
                            self.error = error
                        }
                    } receiveValue: { movie in
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

            resetPlayer {
                self.getMovieVideoUseCase(voiceActing: self.voiceActing, season: season, episode: nextEpisode, favs: self.favs)
                    .receive(on: DispatchQueue.main)
                    .sink { completion in
                        guard case let .failure(error) = completion else { return }

                        withAnimation(.easeInOut) {
                            self.error = error
                        }
                    } receiveValue: { movie in
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

            resetPlayer {
                self.getMovieVideoUseCase(voiceActing: self.voiceActing, season: nextSeason, episode: nextEpisode, favs: self.favs)
                    .receive(on: DispatchQueue.main)
                    .sink { completion in
                        guard case let .failure(error) = completion else { return }

                        withAnimation(.easeInOut) {
                            self.error = error
                        }
                    } receiveValue: { movie in
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
}
