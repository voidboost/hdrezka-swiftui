import Combine
import Dependencies

struct GetSoonMoviesInCollectionUseCase {
    @Dependency(\.collectionsRepository) private var repository

    func callAsFunction(collectionId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        repository.getSoonMoviesInCollection(collectionId: collectionId, page: page)
    }
}

extension GetSoonMoviesInCollectionUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var getSoonMoviesInCollectionUseCase: GetSoonMoviesInCollectionUseCase {
        get { self[GetSoonMoviesInCollectionUseCase.self] }
        set { self[GetSoonMoviesInCollectionUseCase.self] = newValue }
    }
}
