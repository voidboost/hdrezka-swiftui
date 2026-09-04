import Combine
import Dependencies

struct GetLatestMoviesInCollectionUseCase {
    @Dependency(\.collectionsRepository) private var repository

    func callAsFunction(collectionId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        repository.getLatestMoviesInCollection(collectionId: collectionId, page: page)
    }
}

extension GetLatestMoviesInCollectionUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var getLatestMoviesInCollectionUseCase: GetLatestMoviesInCollectionUseCase {
        get { self[GetLatestMoviesInCollectionUseCase.self] }
        set { self[GetLatestMoviesInCollectionUseCase.self] = newValue }
    }
}
