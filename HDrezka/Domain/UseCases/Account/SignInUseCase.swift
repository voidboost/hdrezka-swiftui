import Combine
import Dependencies

struct SignInUseCase {
    @Dependency(\.accountRepository) private var repository

    func callAsFunction(login: String, password: String) -> AnyPublisher<Void, Error> {
        repository.signIn(login: login, password: password)
    }
}

extension SignInUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var signInUseCase: SignInUseCase {
        get { self[SignInUseCase.self] }
        set { self[SignInUseCase.self] = newValue }
    }
}
