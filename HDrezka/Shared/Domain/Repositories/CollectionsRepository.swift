import Combine

protocol CollectionsRepository {
    func getCollections(page: Int) -> AnyPublisher<[MoviesCollection], Error>

    func getWatchingNowMoviesInCollection(collectionId: String, page: Int) -> AnyPublisher<[MovieSimple], Error>

    func getPopularMoviesInCollection(collectionId: String, page: Int) -> AnyPublisher<[MovieSimple], Error>

    func getLatestMoviesInCollection(collectionId: String, page: Int) -> AnyPublisher<[MovieSimple], Error>

    func getSoonMoviesInCollection(collectionId: String, page: Int) -> AnyPublisher<[MovieSimple], Error>
}
