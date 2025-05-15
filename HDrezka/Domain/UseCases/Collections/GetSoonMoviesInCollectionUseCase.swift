import Combine

struct GetSoonMoviesInCollectionUseCase {
    private let repository: CollectionsRepository

    init(repository: CollectionsRepository) {
        self.repository = repository
    }

    func callAsFunction(collectionId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        repository.getSoonMoviesInCollection(collectionId: collectionId, page: page)
    }
}
