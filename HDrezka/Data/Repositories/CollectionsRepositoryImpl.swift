import Alamofire
import Combine
import FactoryKit
import Foundation

struct CollectionsRepositoryImpl: CollectionsRepository {
    @Injected(\.session) private var session

    func getCollections(page: Int) -> AnyPublisher<[MoviesCollection], Error> {
        session.request(CollectionsService.getCollections(page: page))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(CollectionsParser.parseCollections)
            .handleError()
            .eraseToAnyPublisher()
    }
    
    func getWatchingNowMoviesInCollection(collectionId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        session.request(CollectionsService.getMoviesInCollectionWithFilter(collectionId: collectionId, page: page, filter: "watching"))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(CollectionsParser.parseMoviesInCollection)
            .handleError()
            .eraseToAnyPublisher()
    }
    
    func getPopularMoviesInCollection(collectionId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        session.request(CollectionsService.getMoviesInCollectionWithFilter(collectionId: collectionId, page: page, filter: "popular"))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(CollectionsParser.parseMoviesInCollection)
            .handleError()
            .eraseToAnyPublisher()
    }
    
    func getLatestMoviesInCollection(collectionId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        session.request(CollectionsService.getMoviesInCollectionWithFilter(collectionId: collectionId, page: page, filter: "last"))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(CollectionsParser.parseMoviesInCollection)
            .handleError()
            .eraseToAnyPublisher()
    }
    
    func getSoonMoviesInCollection(collectionId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        session.request(CollectionsService.getMoviesInCollectionWithFilter(collectionId: collectionId, page: page, filter: "soon"))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(CollectionsParser.parseMoviesInCollection)
            .handleError()
            .eraseToAnyPublisher()
    }
}
