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

        var videoGravity = Defaults[.videoGravity]
        var ambientLight = Defaults[.ambientLight]
        var mediaControlButtonIsSeeking = Defaults[.mediaControlButtonIsSeeking]
        var isMaskLocked = false
        var pendingSeek: Double?
        var playsAfterSetup = true

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
        }

        var isSeries: Bool {
            seasons != nil && season != nil && episode != nil
        }

        var times: [Int] {
            [900, 1800, 2700, 3600] + (isSeries ? [-1] : [])
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

        var isAmbientLightVisible: Bool {
            ambientLight && videoGravity == .fit && !isPictureInPictureActive
        }

        var trackCommandMode: PlayerEngine.TrackCommandMode {
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

    enum CancelID {
        case engine
        case defaults
        case track
        case hideMask
        case sleepTimer
    }

    let engine: PlayerEngine

    @Dependency(\.appRouter) var appRouter
    @Dependency(\.saveWatchingStateUseCase) var saveWatchingStateUseCase
    @Dependency(\.getMovieThumbnailsUseCase) var getMovieThumbnailsUseCase
    @Dependency(\.getMovieVideoUseCase) var getMovieVideoUseCase
    @Dependency(\.defaultDatabase) var database
    @Dependency(\.continuousClock) var clock

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
}
