import Combine

struct CheckEmailUseCase {
    private let repository: AccountRepository

    init(repository: AccountRepository) {
        self.repository = repository
    }

    func callAsFunction(email: String) -> AnyPublisher<Bool, Error> {
        repository.checkEmail(email: email)
    }
}
