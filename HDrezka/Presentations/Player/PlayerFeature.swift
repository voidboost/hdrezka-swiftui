import AVKit
import ComposableArchitecture
import Defaults
import SQLiteData
import SwiftUI

@Reducer
struct PlayerFeature {
    @ObservableState
    struct State: Equatable {
        let poster: String
        let name: String
        let favs: String
        let voiceActing: MovieVoiceActing
        let hideMainWindow = Defaults[.hideMainWindow]
        let times: [Int]

        var seasons: [MovieSeason]?
        var season: MovieSeason?
        var episode: MovieEpisode?
        var movie: MovieVideo
        var quality: String

        var isReady = false
        var currentTime = 0.0
        var duration = Double.greatestFiniteMagnitude
        var loadedTimeRanges: [CMTimeRange] = []
        var isPlaying = true
        var isLoading = true
        var isMaskShow = true
        var timer: Int?
        var nextTimer: CGFloat?
        var error: EquatableError?
        var subtitles: String?
        var subtitlesOptions: [SubtitleOption] = []
        var thumbnails: WebVTT?
        var routesDetected = false
        var isPictureInPictureActive = false
        var isPictureInPicturePossible = false
        var isFocused = false
        var isDismissed = false

        var rate = Defaults[.rate]
        var isMuted = Defaults[.isMuted]
        var volume = Defaults[.volume]
        var playerFullscreen = Defaults[.playerFullscreen]

        fileprivate var videoGravity = Defaults[.videoGravity]
        fileprivate var ambientLight = Defaults[.ambientLight]
        fileprivate var mediaControlButtonIsSeeking = Defaults[.mediaControlButtonIsSeeking]
        fileprivate var isMaskLocked = false
        fileprivate var pendingSeek: Double?
        fileprivate var playsAfterSetup = true

        init(data: PlayerData) {
            poster = data.details.poster
            name = data.details.nameRussian
            favs = data.details.favs
            voiceActing = data.selectedActing
            seasons = data.seasons
            season = data.selectedSeason
            episode = data.selectedEpisode
            movie = data.movie
            quality = data.selectedQuality

            times = data.seasons != nil && data.selectedSeason != nil && data.selectedEpisode != nil ? [900, 1800, 2700, 3600, -1] : [900, 1800, 2700, 3600]
        }

        var isSeries: Bool {
            seasons != nil && season != nil && episode != nil
        }

        var previousEpisode: (MovieSeason, MovieEpisode)? {
            guard let seasons, let season, let episode else { return nil }

            if let previous = season.episodes.element(before: episode) {
                return (season, previous)
            } else if let previousSeason = seasons.element(before: season), let previous = previousSeason.episodes.last {
                return (previousSeason, previous)
            }

            return nil
        }

        var nextEpisode: (MovieSeason, MovieEpisode)? {
            guard let seasons, let season, let episode else { return nil }

            if let next = season.episodes.element(after: episode) {
                return (season, next)
            } else if let nextSeason = seasons.element(after: season), let next = nextSeason.episodes.first {
                return (nextSeason, next)
            }

            return nil
        }

        var hasPreviousEpisode: Bool {
            previousEpisode != nil
        }

        var hasNextEpisode: Bool {
            nextEpisode != nil
        }

        fileprivate var isAmbientLightVisible: Bool {
            ambientLight && videoGravity == .fit && !isPictureInPictureActive
        }

        fileprivate var trackCommandMode: PlayerEngine.TrackCommandMode {
            if mediaControlButtonIsSeeking {
                .seeking
            } else if isSeries {
                .episodes(hasPrevious: hasPreviousEpisode, hasNext: hasNextEpisode)
            } else {
                .none
            }
        }
    }

    enum MoveDirection {
        case up
        case down
        case left
        case right
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case task
        case disappeared
        case selectPositionLoaded(subtitles: String?)
        case engine(PlayerEvent)
        case thumbnailsLoaded(WebVTT)
        case subtitleOptionsLoaded([SubtitleOption])
        case playbackPositionLoaded(Double?)
        case defaultsChanged(DefaultsChange)
        case videoTapped
        case playPauseTapped
        case toggleMuteTapped
        case volumeChanged(Float)
        case seek(Double)
        case skip(Double)
        case moveCommand(MoveDirection)
        case previousTrackTapped
        case nextTrackTapped
        case trackLoaded(MovieSeason, MovieEpisode, Result<MovieVideo, any Error>)
        case qualitySelected(String)
        case subtitlesSelected(String?)
        case timerSelected(Int?)
        case pictureInPictureTapped
        case userActivity
        case hoverChanged(isActive: Bool)
        case lockMask(Bool)
        case unlockMask(Bool)
        case hideMaskFired
        case sleepTimerFired
        case scenePhaseChanged(isActive: Bool)
        case retryTapped
    }

    enum DefaultsChange {
        case rate(Float)
        case isMuted(Bool)
        case volume(Float)
        case spatialAudio(SpatialAudio)
        case playerFullscreen(Bool)
        case videoGravity(VideoGravity)
        case ambientLight(Bool)
        case mediaControlButtonIsSeeking(Bool)
    }

    private enum CancelID {
        case engine
        case defaults
        case track
        case hideMask
        case sleepTimer
    }

    let engine: PlayerEngine

    @Dependency(\.appRouter) private var appRouter
    @Dependency(\.saveWatchingStateUseCase) private var saveWatchingStateUseCase
    @Dependency(\.getMovieThumbnailsUseCase) private var getMovieThumbnailsUseCase
    @Dependency(\.getMovieVideoUseCase) private var getMovieVideoUseCase
    @Dependency(\.defaultDatabase) private var database
    @Dependency(\.continuousClock) private var clock

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .task:
                return .merge(
                    observeDefaults(),
                    .run { [voiceId = state.voiceActing.voiceId] send in
                        let position = try? await database.read { db in
                            try SelectPosition.where { $0.id.eq(voiceId) }.fetchOne(db)
                        }

                        await send(.selectPositionLoaded(subtitles: position?.subtitles))
                    }
                )

            case .disappeared:
                resetState(&state)

                return .merge(
                    .cancel(id: CancelID.engine),
                    .cancel(id: CancelID.defaults),
                    .cancel(id: CancelID.track),
                    .cancel(id: CancelID.hideMask),
                    .cancel(id: CancelID.sleepTimer)
                )

            case let .selectPositionLoaded(subtitles):
                state.subtitles = subtitles

                return setup(&state, seek: nil, isPlaying: true)

            case let .engine(event):
                return handle(event, &state)

            case let .thumbnailsLoaded(thumbnails):
                state.thumbnails = thumbnails

                return .none

            case let .subtitleOptionsLoaded(options):
                state.subtitlesOptions = options

                return .none

            case let .playbackPositionLoaded(position):
                return perform { [rate = state.rate, isPlaying = state.playsAfterSetup] engine in
                    if let position {
                        let isComplete = await engine.seek(to: position)

                        if isPlaying, isComplete {
                            engine.play(rate: rate)
                        }
                    } else if isPlaying {
                        engine.play(rate: rate)
                    }
                }

            case let .defaultsChanged(change):
                return handle(change, &state)

            case .videoTapped:
                guard state.isReady, !state.isPictureInPictureActive, !state.isLoading else { return .none }

                return togglePlayback(state)

            case .playPauseTapped:
                let resetTimer = resetSleepTimer(&state)

                guard !state.isPictureInPictureActive else { return resetTimer }

                return .merge(resetTimer, togglePlayback(state))

            case .toggleMuteTapped:
                let resetTimer = resetSleepTimer(&state)

                guard !state.isPictureInPictureActive else { return resetTimer }

                return .merge(resetTimer, perform { $0.toggleMute() })

            case let .volumeChanged(volume):
                return perform { $0.setVolume(volume) }

            case let .seek(seconds):
                return perform { _ = await $0.seek(to: seconds) }

            case let .skip(interval):
                return skip(by: interval, &state)

            case let .moveCommand(direction):
                let resetTimer = resetSleepTimer(&state)

                guard state.isReady, !state.isPictureInPictureActive else { return resetTimer }

                switch direction {
                case .up:
                    guard state.volume < 1.0 else { return resetTimer }

                    return .merge(resetTimer, perform { [volume = state.volume] engine in engine.setVolume(min(volume + 0.05, 1.0)) })
                case .down:
                    guard state.volume > 0.0 else { return resetTimer }

                    return .merge(resetTimer, perform { [volume = state.volume] engine in engine.setVolume(max(volume - 0.05, 0.0)) })
                case .left:
                    return .merge(resetTimer, skip(by: -10.0, &state))
                case .right:
                    return .merge(resetTimer, skip(by: 10.0, &state))
                }

            case .previousTrackTapped:
                guard let (season, episode) = state.previousEpisode else { return .none }

                return switchTrack(to: season, episode, &state)

            case .nextTrackTapped:
                guard let (season, episode) = state.nextEpisode else { return .none }

                return switchTrack(to: season, episode, &state)

            case let .trackLoaded(season, episode, .success(movie)):
                guard !movie.needPremium else {
                    state.isDismissed = true

                    return .run { _ in appRouter.present(.premium) }
                }

                state.movie = movie
                state.season = season
                state.episode = episode

                return setup(&state, seek: nil, isPlaying: true)

            case let .trackLoaded(_, _, .failure(error)):
                state.error = EquatableError(error)

                return .none

            case let .qualitySelected(quality):
                state.quality = quality

                let seek = state.currentTime
                let isPlaying = state.isPlaying

                resetState(&state)

                return setup(&state, seek: seek, isPlaying: isPlaying)

            case let .subtitlesSelected(language):
                state.subtitles = language

                return perform { [voiceActing = state.voiceActing, season = state.season, episode = state.episode] engine in
                    guard await engine.selectSubtitles(language) else { return }

                    try? await database.write { db in
                        try SelectPosition
                            .upsert {
                                SelectPosition.Draft(
                                    id: voiceActing.voiceId,
                                    acting: voiceActing.translatorId,
                                    season: season?.seasonId,
                                    episode: episode?.episodeId,
                                    subtitles: language
                                )
                            }
                            .execute(db)
                    }
                }

            case let .timerSelected(timer):
                state.timer = timer

                return resetSleepTimer(&state)

            case .pictureInPictureTapped:
                return perform { $0.startPictureInPicture() }

            case .userActivity:
                return resetSleepTimer(&state)

            case let .hoverChanged(isActive):
                let isMaskShown = isActive
                    ? !state.isPictureInPictureActive
                    : (state.isLoading || !state.isPlaying) && !state.isPictureInPictureActive

                return .merge(
                    resetSleepTimer(&state),
                    showCursor(),
                    setMask(isMaskShown, &state)
                )

            case let .lockMask(isMaskShown):
                state.isMaskLocked = true
                state.isMaskShow = isMaskShown

                return .cancel(id: CancelID.hideMask)

            case let .unlockMask(isMaskShown):
                state.isMaskLocked = false

                return setMask(isMaskShown, &state)

            case .hideMaskFired:
                return .merge(showCursor(false), setMask(false, &state))

            case .sleepTimerFired:
                guard state.isReady else { return .none }

                return perform { $0.pause() }

            case let .scenePhaseChanged(isActive):
                guard !isActive, state.isReady, !state.isPictureInPictureActive, state.isPlaying else { return .none }

                return perform { $0.pause() }

            case .retryTapped:
                resetState(&state)

                return setup(&state, seek: nil, isPlaying: true)
            }
        }
    }

    private func handle(_ event: PlayerEvent, _ state: inout State) -> Effect<Action> {
        switch event {
        case let .time(seconds):
            state.currentTime = seconds
            updateNextTimer(&state)

            return .none

        case let .positionTick(seconds):
            return .run { [voiceActing = state.voiceActing, season = state.season, episode = state.episode] _ in
                try? await database.write { db in
                    try PlayerPosition
                        .upsert {
                            PlayerPosition.Draft(
                                id: PlayerPosition.ID(
                                    id: voiceActing.voiceId,
                                    acting: voiceActing.translatorId,
                                    season: season?.seasonId,
                                    episode: episode?.episodeId
                                ),
                                position: seconds
                            )
                        }
                        .execute(db)
                }
            }

        case .status(.readyToPlay):
            state.isReady = true
            state.isFocused = true
            updateNextTimer(&state)

            return .merge(
                .run { [voiceActing = state.voiceActing, season = state.season, episode = state.episode] _ in
                    if Defaults[.isLoggedIn] {
                        _ = try? await saveWatchingStateUseCase(voiceActing: voiceActing, season: season, episode: episode)
                    }

                    try? await database.write { db in
                        try SelectPosition
                            .upsert {
                                SelectPosition.Draft(
                                    id: voiceActing.voiceId,
                                    acting: voiceActing.translatorId,
                                    season: season?.seasonId,
                                    episode: episode?.episodeId
                                )
                            }
                            .execute(db)
                    }
                },
                .run { [engine, subtitles = state.subtitles] send in
                    let options = await engine.subtitleOptions(selecting: subtitles)

                    await send(.subtitleOptionsLoaded(options), animation: .easeInOut(duration: 0.15))
                },
                perform { [mode = state.trackCommandMode] engine in engine.configureTrackCommands(mode) },
                startPlayback(state)
            )

        case .status:
            return .none

        case let .timeControlStatus(status):
            switch status {
            case .playing:
                state.isPlaying = true
                state.isLoading = false
            case .paused:
                state.isPlaying = false
                state.isLoading = false
            default:
                state.isPlaying = false
                state.isLoading = true
            }

            updateNextTimer(&state)

            return .merge(showCursor(), setMask(!state.isPictureInPictureActive, &state))

        case let .isMuted(isMuted):
            updateNextTimer(&state)

            return .merge(
                .run { _ in Defaults[.isMuted] = isMuted },
                showCursor(),
                setMask(!state.isPictureInPictureActive, &state)
            )

        case let .volume(volume):
            updateNextTimer(&state)

            return .merge(
                perform { engine in
                    Defaults[.volume] = volume

                    engine.setMuted(Defaults[.isMuted])
                },
                showCursor(),
                setMask(!state.isPictureInPictureActive, &state)
            )

        case let .duration(duration):
            state.duration = duration
            updateNextTimer(&state)

            return .none

        case let .loadedTimeRanges(ranges):
            state.loadedTimeRanges = ranges

            return .none

        case let .failed(error):
            resetState(&state)
            state.error = EquatableError(error)

            return perform { $0.reset() }

        case .didPlayToEnd:
            let isPictureInPictureActive = state.isPictureInPictureActive
            let advances = state.timer != -1 && state.hasNextEpisode

            return .run { [engine] send in
                _ = await engine.seek(to: 0)

                if isPictureInPictureActive {
                    await engine.stopPictureInPicture()
                } else if advances {
                    await send(.nextTrackTapped, animation: .easeInOut(duration: 0.15))
                }
            }

        case let .routesDetected(routesDetected):
            state.routesDetected = routesDetected

            return .none

        case let .pictureInPictureActive(isActive):
            state.isPictureInPictureActive = isActive
            updateNextTimer(&state)

            return .merge(
                showCursor(),
                setMask(!isActive, &state),
                perform { [isVisible = state.isAmbientLightVisible] engine in engine.setAmbientLight(isVisible) }
            )

        case let .pictureInPicturePossible(isPossible):
            state.isPictureInPicturePossible = isPossible

            return .none

        case let .remote(command):
            switch command {
            case .play:
                return perform { [rate = state.rate] engine in engine.play(rate: rate) }
            case .pause:
                return perform { $0.pause() }
            case .togglePlayPause:
                return togglePlayback(state)
            case let .changePosition(position):
                return perform { _ = await $0.seek(to: position) }
            case let .changeRate(rate):
                return .run { _ in Defaults[.rate] = rate }
            case let .skip(interval):
                return skip(by: interval, &state)
            case .previousTrack:
                return .run { send in await send(.previousTrackTapped, animation: .easeInOut(duration: 0.15)) }
            case .nextTrack:
                return .run { send in await send(.nextTrackTapped, animation: .easeInOut(duration: 0.15)) }
            }
        }
    }

    private func handle(_ change: DefaultsChange, _ state: inout State) -> Effect<Action> {
        switch change {
        case let .rate(rate):
            state.rate = rate

            return perform { [isPlaying = state.isPlaying] engine in engine.setRate(rate, isPlaying: isPlaying) }

        case let .isMuted(isMuted):
            state.isMuted = isMuted

            return .none

        case let .volume(volume):
            state.volume = volume

            return .none

        case let .spatialAudio(spatialAudio):
            return perform { $0.setSpatialAudio(spatialAudio) }

        case let .playerFullscreen(playerFullscreen):
            state.playerFullscreen = playerFullscreen

            return .none

        case let .videoGravity(videoGravity):
            state.videoGravity = videoGravity

            return perform { [isVisible = state.isAmbientLightVisible] engine in
                engine.setAmbientLight(isVisible)
                engine.setVideoGravity(videoGravity)
            }

        case let .ambientLight(ambientLight):
            state.ambientLight = ambientLight

            return perform { [isVisible = state.isAmbientLightVisible] engine in engine.setAmbientLight(isVisible) }

        case let .mediaControlButtonIsSeeking(isSeeking):
            state.mediaControlButtonIsSeeking = isSeeking

            guard state.isReady else { return .none }

            return perform { [mode = state.trackCommandMode] engine in engine.configureTrackCommands(mode) }
        }
    }

    private func setup(_ state: inout State, seek: Double?, isPlaying: Bool) -> Effect<Action> {
        guard let urls = state.movie.getClosestTo(quality: state.quality)?.compactMap(\.hls), !urls.isEmpty else { return .none }

        state.pendingSeek = seek
        state.playsAfterSetup = isPlaying

        let configuration = PlayerEngine.Configuration(
            urls: urls,
            subtitles: state.movie.subtitles,
            title: state.name,
            album: state.voiceActing.name,
            artist: state.season.flatMap { season in state.episode.map { "Season \(season.name) Episode \($0.name)" } },
            poster: state.poster,
            videoGravity: state.videoGravity,
            ambientLight: state.isAmbientLightVisible,
            volume: state.volume,
            isMuted: state.isMuted,
            rate: state.rate
        )

        var effects: [Effect<Action>] = [
            .run { [engine] send in
                let events = await engine.load(configuration)

                for await event in events {
                    await send(.engine(event), animation: event.animation)
                }
            }
            .cancellable(id: CancelID.engine, cancelInFlight: true),
        ]

        if let path = state.movie.thumbnails {
            effects.append(
                .run { send in
                    guard let thumbnails = try? await getMovieThumbnailsUseCase(path: path) else { return }

                    await send(.thumbnailsLoaded(thumbnails))
                }
            )
        }

        return .merge(effects)
    }

    private func startPlayback(_ state: State) -> Effect<Action> {
        if let seek = state.pendingSeek {
            return perform { [rate = state.rate, isPlaying = state.playsAfterSetup] engine in
                _ = await engine.seek(to: seek)

                if isPlaying {
                    engine.play(rate: rate)
                }
            }
        }

        return .run { [voiceActing = state.voiceActing, season = state.season, episode = state.episode] send in
            let position = try? await database.read { db in
                try PlayerPosition
                    .where {
                        $0.id.id.eq(voiceActing.voiceId) &&
                            $0.id.acting.eq(voiceActing.translatorId) &&
                            $0.id.season.eq(season?.seasonId ?? "") &&
                            $0.id.episode.eq(episode?.episodeId ?? "")
                    }
                    .fetchOne(db)
            }

            await send(.playbackPositionLoaded(position?.position))
        }
    }

    private func switchTrack(to season: MovieSeason, _ episode: MovieEpisode, _ state: inout State) -> Effect<Action> {
        resetState(&state)

        return .run { [engine, voiceActing = state.voiceActing, favs = state.favs] send in
            await engine.reset()

            let result = await Result { try await getMovieVideoUseCase(voiceActing: voiceActing, season: season, episode: episode, favs: favs) }

            await send(.trackLoaded(season, episode, result))
        }
        .cancellable(id: CancelID.track, cancelInFlight: true)
    }

    private func resetState(_ state: inout State) {
        state.isReady = false
        state.error = nil
        state.nextTimer = nil
        state.subtitlesOptions = []
        state.isLoading = true
        state.thumbnails = nil
        state.duration = .greatestFiniteMagnitude
        state.currentTime = 0.0
    }

    private func togglePlayback(_ state: State) -> Effect<Action> {
        perform { [isPlaying = state.isPlaying, rate = state.rate] engine in
            if isPlaying {
                engine.pause()
            } else {
                engine.play(rate: rate)
            }
        }
    }

    private func skip(by interval: Double, _ state: inout State) -> Effect<Action> {
        let target = min(max(state.currentTime + interval, 0.0), state.duration)

        state.currentTime = target

        return perform { [isPlaying = state.isPlaying, rate = state.rate] engine in
            if await engine.seek(to: target), isPlaying {
                engine.play(rate: rate)
            }
        }
    }

    private func setMask(_ isMaskShown: Bool, _ state: inout State) -> Effect<Action> {
        guard !state.isMaskLocked else { return .none }

        state.isMaskShow = isMaskShown

        guard isMaskShown, !state.isLoading, state.isPlaying else { return .cancel(id: CancelID.hideMask) }

        return .run { send in
            try await clock.sleep(for: .seconds(3))

            await send(.hideMaskFired, animation: .easeInOut)
        }
        .cancellable(id: CancelID.hideMask, cancelInFlight: true)
    }

    private func resetSleepTimer(_ state: inout State) -> Effect<Action> {
        updateNextTimer(&state)

        guard let timer = state.timer, timer > 0, state.isPlaying else { return .cancel(id: CancelID.sleepTimer) }

        return .run { send in
            try await clock.sleep(for: .seconds(timer))

            await send(.sleepTimerFired)
        }
        .cancellable(id: CancelID.sleepTimer, cancelInFlight: true)
    }

    private func updateNextTimer(_ state: inout State) {
        let remaining = (state.duration - state.currentTime) / 60

        if remaining > 0, remaining <= 1, state.hasNextEpisode, state.timer != -1, !state.isPictureInPictureActive {
            state.nextTimer = min(remaining, 1.0)
        } else if state.nextTimer != nil {
            state.nextTimer = nil
        }
    }

    private func perform(_ operation: @escaping @MainActor @Sendable (PlayerEngine) async -> Void) -> Effect<Action> {
        .run { [engine] _ in await operation(engine) }
    }

    private func showCursor(_ isShowed: Bool = true) -> Effect<Action> {
        perform { $0.showCursor(isShowed) }
    }

    private func observeDefaults() -> Effect<Action> {
        .run { send in
            await withTaskGroup(of: Void.self) { group in
                group.addTask { for await value in Defaults.updates(.rate, initial: false) { await send(.defaultsChanged(.rate(value))) } }
                group.addTask { for await value in Defaults.updates(.isMuted, initial: false) { await send(.defaultsChanged(.isMuted(value)), animation: .easeInOut(duration: 0.15)) } }
                group.addTask { for await value in Defaults.updates(.volume, initial: false) { await send(.defaultsChanged(.volume(value)), animation: .easeInOut(duration: 0.15)) } }
                group.addTask { for await value in Defaults.updates(.spatialAudio, initial: false) { await send(.defaultsChanged(.spatialAudio(value))) } }
                group.addTask { for await value in Defaults.updates(.playerFullscreen, initial: false) { await send(.defaultsChanged(.playerFullscreen(value))) } }
                group.addTask { for await value in Defaults.updates(.videoGravity, initial: false) { await send(.defaultsChanged(.videoGravity(value))) } }
                group.addTask { for await value in Defaults.updates(.ambientLight, initial: false) { await send(.defaultsChanged(.ambientLight(value))) } }
                group.addTask { for await value in Defaults.updates(.mediaControlButtonIsSeeking, initial: false) { await send(.defaultsChanged(.mediaControlButtonIsSeeking(value))) } }
            }
        }
        .cancellable(id: CancelID.defaults, cancelInFlight: true)
    }
}

private extension PlayerEvent {
    var animation: Animation? {
        switch self {
        case .time, .positionTick, .loadedTimeRanges, .duration, .status, .isMuted, .volume, .remote, .didPlayToEnd:
            nil
        case .timeControlStatus, .routesDetected, .pictureInPicturePossible:
            .easeInOut(duration: 0.15)
        case .failed, .pictureInPictureActive:
            .easeInOut
        }
    }
}
