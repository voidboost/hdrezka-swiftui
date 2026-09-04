import Combine
import Dependencies

protocol CollectionsRepository {
    func getCollections(page: Int) -> AnyPublisher<[MoviesCollection], Error>

    func getWatchingNowMoviesInCollection(collectionId: String, page: Int) -> AnyPublisher<[MovieSimple], Error>

    func getPopularMoviesInCollection(collectionId: String, page: Int) -> AnyPublisher<[MovieSimple], Error>

    func getLatestMoviesInCollection(collectionId: String, page: Int) -> AnyPublisher<[MovieSimple], Error>

    func getSoonMoviesInCollection(collectionId: String, page: Int) -> AnyPublisher<[MovieSimple], Error>
}

private enum CollectionsRepositoryKey: DependencyKey {
    static var liveValue: any CollectionsRepository = CollectionsRepositoryImpl()
}

extension DependencyValues {
    var collectionsRepository: any CollectionsRepository {
        get { self[CollectionsRepositoryKey.self] }
        set { self[CollectionsRepositoryKey.self] = newValue }
    }
}
