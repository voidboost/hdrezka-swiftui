import ComposableArchitecture
import SwiftUI

@Reducer
struct SignInFeature {
    @ObservableState
    struct State: Equatable {
        var username = ""
        var password = ""
        var status: EmptyState = .data

        var canSubmit: Bool {
            !username.isEmpty && !password.isEmpty
        }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case submit
        case cancelRequest
        case retry
        case signedIn(Result<Void, any Error>)
        case restoreTapped
        case signUpTapped
        case delegate(Delegate)

        enum Delegate {
            case showRestore
            case showSignUp
        }
    }

    private enum CancelID { case request }

    @Dependency(\.signInUseCase) private var signInUseCase
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

                return .run { [username = state.username, password = state.password] send in
                    let result = await Result { try await signInUseCase(login: username, password: password) }

                    await send(.signedIn(result), animation: .easeInOut)
                }
                .cancellable(id: CancelID.request)

            case .cancelRequest, .retry:
                state.status = .data

                return .cancel(id: CancelID.request)

            case .signedIn(.success):
                return .run { _ in await dismiss() }

            case let .signedIn(.failure(error)):
                state.status = .error(error)

                return .none

            case .restoreTapped:
                return .send(.delegate(.showRestore))

            case .signUpTapped:
                return .send(.delegate(.showSignUp))

            case .delegate:
                return .none
            }
        }
    }
}
