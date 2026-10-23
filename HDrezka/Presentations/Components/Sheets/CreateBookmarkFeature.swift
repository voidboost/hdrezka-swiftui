import ComposableArchitecture
import SwiftUI

@Reducer
struct CreateBookmarkFeature {
    @ObservableState
    struct State: Equatable {
        var name = ""
        var status: EmptyState = .data

        var canSubmit: Bool {
            !name.trim().isEmpty
        }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case submit
        case cancelRequest
        case retry
        case created(Result<Bookmark, any Error>)
    }

    private enum CancelID { case request }

    @Dependency(\.createBookmarksCategoryUseCase) private var createBookmarksCategoryUseCase
    @Dependency(\.dismiss) private var dismiss

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .submit:
                guard state.canSubmit else { return .none }

                state.status = .loading

                return .run { [name = state.name.trim()] send in
                    let result = await Result { try await createBookmarksCategoryUseCase(name: name) }

                    await send(.created(result), animation: .easeInOut)
                }
                .cancellable(id: CancelID.request)

            case .cancelRequest, .retry:
                state.status = .data

                return .cancel(id: CancelID.request)

            case .created(.success):
                return .run { _ in await dismiss() }

            case let .created(.failure(error)):
                state.status = .error(error)

                return .none
            }
        }
    }
}
