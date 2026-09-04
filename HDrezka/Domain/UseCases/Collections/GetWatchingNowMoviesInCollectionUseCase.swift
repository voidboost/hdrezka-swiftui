import Combine
import Dependencies

struct GetWatchingNowMoviesInCollectionUseCase {
    @Dependency(\.collectionsRepository) private var repository

    func callAsFunction(collectionId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        repository.getWatchingNowMoviesInCollection(collectionId: collectionId, page: page)
    }
}

extension GetWatchingNowMoviesInCollectionUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var getWatchingNowMoviesInCollectionUseCase: GetWatchingNowMoviesInCollectionUseCase {
        get { self[GetWatchingNowMoviesInCollectionUseCase.self] }
        set { self[GetWatchingNowMoviesInCollectionUseCase.self] = newValue }
    }
}
