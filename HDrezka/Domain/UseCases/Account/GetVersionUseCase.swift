import Combine

struct GetVersionUseCase {
    private let repository: AccountRepository

    init(repository: AccountRepository) {
        self.repository = repository
    }

    func callAsFunction() -> AnyPublisher<String, Error> {
        repository.getVersion()
    }
}
