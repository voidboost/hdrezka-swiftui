import ComposableArchitecture
import SwiftUI

@Reducer
struct HomeFeature {
    @ObservableState
    struct State: Equatable {
        var categories: DataState<[Category]> = .loading
        var paginationState: DataPaginationState = .idle
        @Presents var seriesUpdates: SeriesUpdatesFeature.State?

        fileprivate var nextPage: Categories?
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case reload
        case loadMore(reset: Bool = false)
        case categoryLoaded(Categories, isInitial: Bool, Result<[MovieSimple], any Error>)
        case seriesUpdatesTapped
        case seriesUpdates(PresentationAction<SeriesUpdatesFeature.Action>)
        case delegate(Delegate)

        enum Delegate {
            case push(Destinations)
        }
    }

    private enum CancelID { case load }

    @Dependency(\.getHotMoviesUseCase) private var getHotMoviesUseCase
//    @Dependency(\.getFeaturedMoviesUseCase) private var getFeaturedMoviesUseCase
    @Dependency(\.getWatchingNowMoviesUseCase) private var getWatchingNowMoviesUseCase
    @Dependency(\.getLatestMoviesUseCase) private var getLatestMoviesUseCase
    @Dependency(\.getLatestNewestMoviesUseCase) private var getLatestNewestMoviesUseCase
    @Dependency(\.getPopularMoviesUseCase) private var getPopularMoviesUseCase
    @Dependency(\.getSoonMoviesUseCase) private var getSoonMoviesUseCase
    @Dependency(\.uuid) private var uuid

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .onAppear:
                guard state.categories.data == nil else { return .none }

                return .send(.reload)

            case .reload:
                state.categories = .loading
                state.paginationState = .idle
                state.nextPage = Categories.allCases.first

                guard let page = state.nextPage else { return .cancel(id: CancelID.load) }

                return load(page, isInitial: true)

            case let .loadMore(reset):
                guard let page = state.nextPage, state.paginationState == .idle || reset else { return .none }

                state.paginationState = .loading

                return load(page, isInitial: false)

            case let .categoryLoaded(category, isInitial, result):
                if case .success = result {
                    state.nextPage = Categories.allCases.element(after: category)
                }

                state.paginationState = state.categories.receivePage(
                    result.map { [Category(category: category, title: category.localized, movies: $0, id: uuid())] },
                    isInitial: isInitial
                )

                return .none

            case .seriesUpdatesTapped:
                state.seriesUpdates = SeriesUpdatesFeature.State()

                return .none

            case let .seriesUpdates(.presented(.delegate(.openMovie(movie)))):
                return .send(.delegate(.push(.details(movie))))

            case .seriesUpdates, .delegate:
                return .none
            }
        }
        .ifLet(\.$seriesUpdates, action: \.seriesUpdates) {
            SeriesUpdatesFeature()
        }
    }

    private func load(_ category: Categories, isInitial: Bool) -> Effect<Action> {
        .run { send in
            let result = await Result { try await movies(category) }

            await send(.categoryLoaded(category, isInitial: isInitial, result), animation: .easeInOut)
        }
        .cancellable(id: CancelID.load, cancelInFlight: true)
    }

    private func movies(_ category: Categories) async throws -> [MovieSimple] {
        switch category {
        case .hot: try await getHotMoviesUseCase(genre: 0)
//        case .featured: try await getFeaturedMoviesUseCase(page: 1, genre: 0)
        case .watchingNow: try await getWatchingNowMoviesUseCase(page: 1, genre: 0)
        case .latest: try await getLatestMoviesUseCase(page: 1, genre: 0)
        case .newest: try await getLatestNewestMoviesUseCase(page: 1, genre: 0)
        case .popular: try await getPopularMoviesUseCase(page: 1, genre: 0)
        case .soon: try await getSoonMoviesUseCase(page: 1, genre: 0)
        }
    }
}
