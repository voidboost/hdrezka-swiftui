import Combine

struct LogoutUseCase {
    private let repository: AccountRepository

    init(repository: AccountRepository) {
        self.repository = repository
    }

    func callAsFunction() -> AnyPublisher<Bool, Error> {
        repository.logout()
    }
}
