import ComposableArchitecture
import SwiftUI

@Reducer
struct RestoreFeature {
    @ObservableState
    struct State: Equatable {
        var login = ""
        var email = ""
        var status: EmptyState = .data
        var isSuccessPresented = false
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case submit
        case cancelRequest
        case retry
        case restored(Result<String?, any Error>)
        case signInTapped
        case delegate(Delegate)

        enum Delegate {
            case showSignIn
        }
    }

    private enum CancelID { case request }

    @Dependency(\.restoreUseCase) private var restoreUseCase

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .submit:
                state.status = .loading

                return .run { [login = state.login] send in
                    let result = await Result { try await restoreUseCase(login: login) }

                    await send(.restored(result), animation: .easeInOut)
                }
                .cancellable(id: CancelID.request)

            case .cancelRequest, .retry:
                state.status = .data

                return .cancel(id: CancelID.request)

            case let .restored(.success(email)):
                guard let email, !email.isEmpty else {
                    state.status = .error(HDrezkaError.unknown)

                    return .none
                }

                state.email = email
                state.isSuccessPresented = true

                return .none

            case let .restored(.failure(error)):
                state.status = .error(error)

                return .none

            case .signInTapped:
                return .send(.delegate(.showSignIn))

            case .delegate:
                return .none
            }
        }
    }
}
