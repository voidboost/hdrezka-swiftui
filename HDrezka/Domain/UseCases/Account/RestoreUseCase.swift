import Combine

struct RestoreUseCase {
    private let repository: AccountRepository

    init(repository: AccountRepository) {
        self.repository = repository
    }

    func callAsFunction(login: String) -> AnyPublisher<String?, Error> {
        repository.restore(login: login)
    }
}
