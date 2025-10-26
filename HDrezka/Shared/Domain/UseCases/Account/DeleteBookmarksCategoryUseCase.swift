import Combine

struct DeleteBookmarksCategoryUseCase {
    private let repository: AccountRepository

    init(repository: AccountRepository) {
        self.repository = repository
    }

    func callAsFunction(id: Int) -> AnyPublisher<Bool, Error> {
        repository.deleteBookmarksCategory(id: id)
    }
}
