import Combine

struct CheckUsernameUseCase {
    private let repository: AccountRepository

    init(repository: AccountRepository) {
        self.repository = repository
    }

    func callAsFunction(username: String) -> AnyPublisher<Bool, Error> {
        repository.checkUsername(username: username)
    }
}
