import Combine

struct SignUpUseCase {
    private let repository: AccountRepository

    init(repository: AccountRepository) {
        self.repository = repository
    }

    func callAsFunction(email: String, login: String, password: String, verifyCode: String, step: Int) -> AnyPublisher<Void, Error> {
        repository.signUp(email: email, login: login, password: password, verifyCode: verifyCode, step: step)
    }
}
