import Combine

struct CreateBookmarksCategoryUseCase {
    private let repository: AccountRepository

    init(repository: AccountRepository) {
        self.repository = repository
    }

    func callAsFunction(name: String) -> AnyPublisher<Bookmark, Error> {
        repository.createBookmarksCategory(name: name)
    }
}
