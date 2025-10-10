import Combine

struct LogoutUseCase {
    private let repository: AccountRepository

    init(repository: AccountRepository) {
        self.repository = repository
    }

    func callAsFunction() {
        repository.logout()
    }
}
