import Combine

struct GetPopularMoviesInCollectionUseCase {
    private let repository: CollectionsRepository

    init(repository: CollectionsRepository) {
        self.repository = repository
    }

    func callAsFunction(collectionId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        repository.getPopularMoviesInCollection(collectionId: collectionId, page: page)
    }
}
