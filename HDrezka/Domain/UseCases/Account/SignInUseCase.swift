import Combine

struct SignInUseCase {
    private let repository: AccountRepository

    init(repository: AccountRepository) {
        self.repository = repository
    }

    func callAsFunction(login: String, password: String) -> AnyPublisher<Bool, Error> {
        repository.signIn(login: login, password: password)
    }
}
