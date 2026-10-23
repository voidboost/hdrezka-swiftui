import ComposableArchitecture
import SwiftUI

@Reducer
struct CategoriesFeature {
    @ObservableState
    struct State: Equatable {
        fileprivate var hasAppeared = false

        var types: DataState<[MovieType]> = .loading
    }

    enum Action {
        case onAppear
        case reload
        case typesLoaded(Result<[MovieType], any Error>)
    }

    private enum CancelID { case load }

    @Dependency(\.categoriesUseCase) private var categoriesUseCase

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.types.data == nil, !state.hasAppeared || state.types.error != nil else { return .none }

                state.hasAppeared = true

                return .send(.reload)

            case .reload:
                state.types = .loading

                return .run { send in
                    let result = await Result { try await categoriesUseCase() }

                    await send(.typesLoaded(result), animation: .easeInOut)
                }
                .cancellable(id: CancelID.load, cancelInFlight: true)

            case let .typesLoaded(.success(types)):
                state.types = .data(types)

                return .none

            case let .typesLoaded(.failure(error)):
                state.types = .error(error)

                return .none
            }
        }
    }
}
