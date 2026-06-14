import Combine

struct MoveBetweenBookmarksUseCase {
    private let repository: AccountRepository

    init(repository: AccountRepository) {
        self.repository = repository
    }

    func callAsFunction(movies: [String], fromBookmarkUserCategory: Int, toBookmarkUserCategory: Int) -> AnyPublisher<Int, Error> {
        repository.moveBetweenBookmarks(movies: movies, fromBookmarkUserCategory: fromBookmarkUserCategory, toBookmarkUserCategory: toBookmarkUserCategory)
    }
}
