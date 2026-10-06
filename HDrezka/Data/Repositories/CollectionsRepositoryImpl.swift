import Alamofire
import Combine
import Dependencies
import Foundation

struct CollectionsRepositoryImpl: CollectionsRepository {
    @Dependency(\.session) private var session

    private func moviesInCollection(collectionId: String, page: Int, filter: String) -> AnyPublisher<[MovieSimple], Error> {
        session.string(CollectionsService.getMoviesInCollectionWithFilter(collectionId: collectionId, page: page, filter: filter), parse: CollectionsParser.parseMoviesInCollection)
    }

    func getCollections(page: Int) -> AnyPublisher<[MoviesCollection], Error> {
        session.string(CollectionsService.getCollections(page: page), parse: CollectionsParser.parseCollections)
    }

    func getWatchingNowMoviesInCollection(collectionId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        moviesInCollection(collectionId: collectionId, page: page, filter: "watching")
    }

    func getPopularMoviesInCollection(collectionId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        moviesInCollection(collectionId: collectionId, page: page, filter: "popular")
    }

    func getLatestMoviesInCollection(collectionId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        moviesInCollection(collectionId: collectionId, page: page, filter: "last")
    }

    func getSoonMoviesInCollection(collectionId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        moviesInCollection(collectionId: collectionId, page: page, filter: "soon")
    }
}
