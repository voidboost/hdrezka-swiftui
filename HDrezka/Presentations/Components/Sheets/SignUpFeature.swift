import ComposableArchitecture
import SwiftUI

@Reducer
struct SignUpFeature {
    enum Step: Int, CaseIterable, Identifiable {
        case first = 1
        case second
        case third

        var id: Self {
            self
        }
    }

    @ObservableState
    struct State: Equatable {
        var email = ""
        var username = ""
        var password1 = ""
        var password2 = ""
        var verifyCode = ""
        var step: Step = .first
        var status: EmptyState = .data
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case submit
        case cancelRequest
        case retry
        case cancelVerification
        case signedUp(Result<Void, any Error>)
        case signInTapped
        case delegate(Delegate)

        enum Delegate {
            case showSignIn
        }
    }

    private enum CancelID { case request }

    @Dependency(\.signUpUseCase) private var signUpUseCase
    @Dependency(\.dismiss) private var dismiss

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .submit:
                state.status = .loading

                return .run { [state] send in
                    let result = await Result {
                        try await signUpUseCase(email: state.email, login: state.username, password: state.password1, verifyCode: state.verifyCode, step: state.step.rawValue)
                    }

                    await send(.signedUp(result), animation: .easeInOut)
                }
                .cancellable(id: CancelID.request)

            case .cancelRequest, .retry:
                state.status = .data

                return .cancel(id: CancelID.request)

            case .cancelVerification:
                state.step = .first

                return .none

            case .signedUp(.success):
                guard state.step != Step.allCases.last else {
                    return .run { _ in await dismiss() }
                }

                state.step = Step.allCases.element(after: state.step) ?? .first
                state.status = .data

                return .none

            case let .signedUp(.failure(error)):
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
