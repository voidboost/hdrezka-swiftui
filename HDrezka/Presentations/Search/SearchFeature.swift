import ComposableArchitecture
import SwiftUI

@Reducer
struct SearchFeature {
    @ObservableState
    struct State: Equatable {
        var movies: DataState<[MovieSimple]> = .data([])
        var paginationState: DataPaginationState = .idle

        var title = String(localized: "key.search")

        var query = ""

        fileprivate var page = 1
        fileprivate var loadedQuery = ""
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case reload
        case loadMore
        case search(force: Bool)
        case moviesLoaded(isInitial: Bool, Result<[MovieSimple], any Error>)
    }

    private enum CancelID {
        case debounce
        case load
    }

    @Dependency(\.searchUseCase) private var searchUseCase
    @Dependency(\.continuousClock) private var clock

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding(\.query):
                return debounce(force: state.query.trim().isEmpty)

            case .binding:
                return .none

            case .onAppear:
                guard state.movies.data == nil else { return .none }

                return debounce(force: true)

            case .reload:
                return debounce(force: true)

            case let .search(force):
                let query = state.query.trim()

                guard force || query != state.loadedQuery || state.movies.error != nil else { return .none }

                state.loadedQuery = query
                state.paginationState = .idle
                state.page = 1

                guard !query.isEmpty else {
                    state.title = String(localized: "key.search")
                    state.movies = .data([])

                    return .cancel(id: CancelID.load)
                }

                state.movies = .loading
                state.title = String(localized: "key.search.result-\(query)")

                return load(query: query, page: state.page, isInitial: true)

            case .loadMore:
                guard state.paginationState == .idle, !state.loadedQuery.isEmpty else { return .none }

                state.paginationState = .loading

                return load(query: state.loadedQuery, page: state.page, isInitial: false)

            case let .moviesLoaded(isInitial, result):
                if case .success = result {
                    state.page += 1
                }

                state.paginationState = state.movies.receivePage(result, isInitial: isInitial, emptyPageIsError: true)

                return .none
            }
        }
    }

    private func debounce(force: Bool) -> Effect<Action> {
        .run { send in
            if !force {
                try await clock.sleep(for: .milliseconds(500))
            }

            await send(.search(force: force), animation: .easeInOut)
        }
        .cancellable(id: CancelID.debounce, cancelInFlight: true)
    }

    private func load(query: String, page: Int, isInitial: Bool) -> Effect<Action> {
        .run { send in
            let result = await Result { try await searchUseCase(query: query, page: page) }

            await send(.moviesLoaded(isInitial: isInitial, result), animation: .easeInOut)
        }
        .cancellable(id: CancelID.load, cancelInFlight: true)
    }
}
