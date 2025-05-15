import Combine

struct GetLatestMoviesInCollectionUseCase {
    private let repository: CollectionsRepository

    init(repository: CollectionsRepository) {
        self.repository = repository
    }

    func callAsFunction(collectionId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        repository.getLatestMoviesInCollection(collectionId: collectionId, page: page)
    }
}
