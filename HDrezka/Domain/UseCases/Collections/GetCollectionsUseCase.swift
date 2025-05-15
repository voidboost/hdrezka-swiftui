import Combine

struct GetCollectionsUseCase {
    private let repository: CollectionsRepository

    init(repository: CollectionsRepository) {
        self.repository = repository
    }

    func callAsFunction(page: Int) -> AnyPublisher<[MoviesCollection], Error> {
        repository.getCollections(page: page)
    }
}
