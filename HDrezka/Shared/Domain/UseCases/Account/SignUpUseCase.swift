import Combine

struct SignUpUseCase {
    private let repository: AccountRepository

    init(repository: AccountRepository) {
        self.repository = repository
    }

    func callAsFunction(email: String, login: String, password: String) -> AnyPublisher<Bool, Error> {
        repository.signUp(email: email, login: login, password: password)
    }
}
