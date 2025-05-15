import Combine

struct GetWatchingNowMoviesInCollectionUseCase {
    private let repository: CollectionsRepository

    init(repository: CollectionsRepository) {
        self.repository = repository
    }

    func callAsFunction(collectionId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        repository.getWatchingNowMoviesInCollection(collectionId: collectionId, page: page)
    }
}
