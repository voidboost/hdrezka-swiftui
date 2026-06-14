import Combine

struct RemoveFromBookmarksUseCase {
    private let repository: AccountRepository

    init(repository: AccountRepository) {
        self.repository = repository
    }

    func callAsFunction(movies: [String], bookmarkUserCategory: Int) -> AnyPublisher<Bool, Error> {
        repository.removeFromBookmarks(movies: movies, bookmarkUserCategory: bookmarkUserCategory)
    }
}
