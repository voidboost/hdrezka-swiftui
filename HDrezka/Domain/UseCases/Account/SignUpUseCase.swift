import Combine
import Dependencies

struct SignUpUseCase {
    @Dependency(\.accountRepository) private var repository

    func callAsFunction(email: String, login: String, password: String, verifyCode: String, step: Int) -> AnyPublisher<Void, Error> {
        repository.signUp(email: email, login: login, password: password, verifyCode: verifyCode, step: step)
    }
}

extension SignUpUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var signUpUseCase: SignUpUseCase {
        get { self[SignUpUseCase.self] }
        set { self[SignUpUseCase.self] = newValue }
    }
}
