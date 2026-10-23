import ComposableArchitecture
import SwiftUI

@Reducer
struct CollectionsFeature {
    @ObservableState
    struct State: Equatable {
        var collections: DataState<[MoviesCollection]> = .idle
        var paginationState: DataPaginationState = .idle

        fileprivate var page = 1
    }

    enum Action {
        case onAppear
        case reload
        case loadMore
        case collectionsLoaded(isInitial: Bool, Result<[MoviesCollection], any Error>)
    }

    private enum CancelID { case load }

    @Dependency(\.getCollectionsUseCase) private var getCollectionsUseCase

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.collections.needsLoad else { return .none }

                return .send(.reload)

            case .reload:
                state.collections = .loading
                state.paginationState = .idle
                state.page = 1

                return load(page: state.page, isInitial: true)

            case .loadMore:
                guard state.paginationState == .idle else { return .none }

                state.paginationState = .loading

                return load(page: state.page, isInitial: false)

            case let .collectionsLoaded(isInitial, result):
                if case .success = result {
                    state.page += 1
                }

                state.paginationState = state.collections.receivePage(result, isInitial: isInitial)

                return .none
            }
        }
    }

    private func load(page: Int, isInitial: Bool) -> Effect<Action> {
        .run { send in
            let result = await Result { try await getCollectionsUseCase(page: page) }

            await send(.collectionsLoaded(isInitial: isInitial, result), animation: .easeInOut)
        }
        .cancellable(id: CancelID.load, cancelInFlight: true)
    }
}
