import ComposableArchitecture
import Defaults
import SQLiteData
import SwiftUI

@Reducer
struct MovieSelectionFeature {
    @ObservableState
    struct State: Equatable {
        let id: String

        var details: MovieDetailed?
        var seasons: [MovieSeason]?
        var selectedActing: MovieVoiceActing?
        var selectedSeason: MovieSeason?
        var selectedEpisode: MovieEpisode?
        var selectedQuality: String?
        var selectedSubtitles: MovieSubtitles?
        var movie: MovieVideo?

        var error: EquatableError?
        var isErrorPresented = false

        fileprivate var selectPosition: SelectPosition?

        init(id: String) {
            self.id = id
        }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case detailsLoaded(Result<(MovieDetailed, SelectPosition?), any Error>)
        case seasonsLoaded(Result<[MovieSeason], any Error>)
        case videoLoaded(Result<MovieVideo, any Error>)
        case rememberSelection
        case showError(any Error)
    }

    private enum CancelID {
        case details
        case seasons
        case video
    }

    @Dependency(\.getMovieDetailsUseCase) private var getMovieDetailsUseCase
    @Dependency(\.getMovieVideoUseCase) private var getMovieVideoUseCase
    @Dependency(\.getSeriesSeasonsUseCase) private var getSeriesSeasonsUseCase
    @Dependency(\.saveWatchingStateUseCase) private var saveWatchingStateUseCase
    @Dependency(\.defaultDatabase) private var database
    @Dependency(\.appRouter) private var appRouter
    @Dependency(\.dismiss) private var dismiss

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding(\.selectedActing):
                return actingChanged(&state)

            case .binding(\.selectedSeason):
                return seasonChanged(&state)

            case .binding(\.selectedEpisode):
                return episodeChanged(&state)

            case .binding:
                return .none

            case .onAppear:
                guard state.details == nil else { return .none }

                return .run { [id = state.id] send in
                    let result = await Result {
                        let details = try await getMovieDetailsUseCase(movieId: id)

                        let selectPosition: SelectPosition? = if let movieId = details.movieId.id {
                            try? await database.read { db in
                                try SelectPosition.where { $0.id.eq(movieId) }.fetchOne(db)
                            }
                        } else {
                            nil
                        }

                        return (details, selectPosition)
                    }

                    await send(.detailsLoaded(result), animation: .easeInOut)
                }
                .cancellable(id: CancelID.details, cancelInFlight: true)

            case let .detailsLoaded(.success((details, selectPosition))):
                state.details = details
                state.selectPosition = selectPosition

                guard let acting = details.voiceActing else { return .none }

                let available = acting.filter { Defaults[.isUserPremium] != nil || !$0.isPremium }

                state.selectedActing = available.preferred(
                    saved: Defaults[.isLoggedIn] ? nil : selectPosition?.acting,
                    series: details.series?.acting,
                    id: \.translatorId,
                    isSelected: \.isSelected
                ) ?? acting.first

                return actingChanged(&state)

            case let .seasonsLoaded(.success(seasons)):
                state.seasons = seasons

                state.selectedSeason = seasons.preferred(
                    saved: Defaults[.isLoggedIn] ? nil : state.selectPosition?.season,
                    series: state.details?.series?.season,
                    id: \.seasonId,
                    isSelected: \.isSelected
                )

                return seasonChanged(&state)

            case let .videoLoaded(.success(movie)):
                guard !movie.needPremium else {
                    return .run { _ in
                        await dismiss()

                        appRouter.present(.premium)
                    }
                }

                state.movie = movie

                let qualities = movie.getAvailableQualities()
                let defaultQuality = Defaults[.defaultQuality]

                if defaultQuality != .ask,
                   defaultQuality != .highest,
                   qualities.contains(defaultQuality.rawValue)
                {
                    state.selectedQuality = defaultQuality.rawValue
                } else if defaultQuality == .highest,
                          let highest = qualities.last
                {
                    state.selectedQuality = highest
                }

                state.selectedSubtitles = movie.subtitles.first(where: { $0.lang == state.selectPosition?.subtitles?.replacingOccurrences(of: "uk", with: "ua") })

                return .none

            case let .detailsLoaded(.failure(error)),
                 let .seasonsLoaded(.failure(error)),
                 let .videoLoaded(.failure(error)),
                 let .showError(error):
                state.error = EquatableError(error)
                state.isErrorPresented = true

                return .none

            case .rememberSelection:
                guard let selectedActing = state.selectedActing else { return .none }

                return .run { [selectedSeason = state.selectedSeason, selectedEpisode = state.selectedEpisode, subtitles = state.selectedSubtitles?.lang.replacingOccurrences(of: "ua", with: "uk")] _ in
                    if Defaults[.isLoggedIn] {
                        try? await saveWatchingStateUseCase(voiceActing: selectedActing, season: selectedSeason, episode: selectedEpisode)
                    }

                    try? await database.write { db in
                        try SelectPosition
                            .upsert {
                                SelectPosition.Draft(
                                    id: selectedActing.voiceId,
                                    acting: selectedActing.translatorId,
                                    season: selectedSeason?.seasonId,
                                    episode: selectedEpisode?.episodeId,
                                    subtitles: subtitles
                                )
                            }
                            .execute(db)
                    }
                }
            }
        }
    }

    private func actingChanged(_ state: inout State) -> Effect<Action> {
        state.selectedSeason = nil
        state.selectedEpisode = nil
        state.selectedQuality = nil
        state.seasons = nil
        state.movie = nil

        let cancel = Effect<Action>.merge(.cancel(id: CancelID.seasons), .cancel(id: CancelID.video))

        guard let details = state.details, let selectedActing = state.selectedActing else { return cancel }

        guard details.series != nil else {
            return .concatenate(cancel, loadVideo(details: details, acting: selectedActing, season: nil, episode: nil))
        }

        guard let movieId = details.movieId.id else {
            state.error = EquatableError(HDrezkaError.unknown)
            state.isErrorPresented = true

            return cancel
        }

        return .concatenate(
            cancel,
            .run { send in
                let result = await Result { try await getSeriesSeasonsUseCase(movieId: movieId, voiceActing: selectedActing, favs: details.favs) }

                await send(.seasonsLoaded(result), animation: .easeInOut)
            }
            .cancellable(id: CancelID.seasons, cancelInFlight: true)
        )
    }

    private func seasonChanged(_ state: inout State) -> Effect<Action> {
        state.selectedQuality = nil
        state.movie = nil

        state.selectedEpisode = state.selectedSeason?.episodes.preferred(
            saved: Defaults[.isLoggedIn] ? nil : state.selectPosition?.episode,
            series: state.details?.series?.episode,
            id: \.episodeId,
            isSelected: \.isSelected
        )

        return episodeChanged(&state)
    }

    private func episodeChanged(_ state: inout State) -> Effect<Action> {
        state.selectedQuality = nil
        state.movie = nil

        guard let details = state.details,
              let selectedSeason = state.selectedSeason,
              let selectedEpisode = state.selectedEpisode,
              let selectedActing = state.selectedActing
        else {
            return .cancel(id: CancelID.video)
        }

        return loadVideo(details: details, acting: selectedActing, season: selectedSeason, episode: selectedEpisode)
    }

    private func loadVideo(details: MovieDetailed, acting: MovieVoiceActing, season: MovieSeason?, episode: MovieEpisode?) -> Effect<Action> {
        .run { send in
            let result = await Result { try await getMovieVideoUseCase(voiceActing: acting, season: season, episode: episode, favs: details.favs) }

            await send(.videoLoaded(result), animation: .easeInOut)
        }
        .cancellable(id: CancelID.video, cancelInFlight: true)
    }
}

private extension Array {
    func preferred(saved: String?, series: String?, id: (Element) -> String, isSelected: (Element) -> Bool) -> Element? {
        first { saved != nil && id($0) == saved }
            ?? first { series != nil && id($0) == series }
            ?? first(where: isSelected)
            ?? first
    }
}
