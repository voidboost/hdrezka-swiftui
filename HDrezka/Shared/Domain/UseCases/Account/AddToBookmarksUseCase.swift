import Combine

struct AddToBookmarksUseCase {
    private let repository: AccountRepository

    init(repository: AccountRepository) {
        self.repository = repository
    }

    func callAsFunction(movieId: String, bookmarkUserCategory: Int) -> AnyPublisher<Bool, Error> {
        repository.addToBookmarks(movieId: movieId, bookmarkUserCategory: bookmarkUserCategory)
    }
}
