import Combine

struct GetBookmarksByCategoryAddedUseCase {
    private let repository: AccountRepository

    init(repository: AccountRepository) {
        self.repository = repository
    }

    func callAsFunction(id: Int, genre: Int, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        repository.getBookmarksByCategoryAdded(id: id, genre: genre, page: page)
    }
}
