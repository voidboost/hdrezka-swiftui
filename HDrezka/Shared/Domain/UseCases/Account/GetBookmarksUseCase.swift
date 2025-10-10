import Combine

struct GetBookmarksUseCase {
    private let repository: AccountRepository

    init(repository: AccountRepository) {
        self.repository = repository
    }

    func callAsFunction() -> AnyPublisher<[Bookmark], Error> {
        repository.getBookmarks()
    }
}
