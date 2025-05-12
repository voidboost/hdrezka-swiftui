import Alamofire
import Combine
import Foundation

protocol CollectionsRepository {
    func getCollections(page: Int) -> AnyPublisher<[MoviesCollection], Error>
    
    func getWatchingNowMoviesInCollection(collectionId: String, page: Int) -> AnyPublisher<[MovieSimple], Error>
    
    func getPopularMoviesInCollection(collectionId: String, page: Int) -> AnyPublisher<[MovieSimple], Error>
    
    func getLatestMoviesInCollection(collectionId: String, page: Int) -> AnyPublisher<[MovieSimple], Error>
    
    func getSoonMoviesInCollection(collectionId: String, page: Int) -> AnyPublisher<[MovieSimple], Error>
}

struct CollectionsRepositoryImpl: CollectionsRepository {
    func getCollections(page: Int) -> AnyPublisher<[MoviesCollection], Error> {
        Const.session.request(CollectionsService.getCollections(page: page))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(CollectionsParser.parseCollections)
            .handleError()
            .eraseToAnyPublisher()
    }
    
    func getWatchingNowMoviesInCollection(collectionId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        Const.session.request(CollectionsService.getMoviesInCollectionWithFilter(collectionId: collectionId, page: page, filter: "watching"))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(CollectionsParser.parseMoviesInCollection)
            .handleError()
            .eraseToAnyPublisher()
    }
    
    func getPopularMoviesInCollection(collectionId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        Const.session.request(CollectionsService.getMoviesInCollectionWithFilter(collectionId: collectionId, page: page, filter: "popular"))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(CollectionsParser.parseMoviesInCollection)
            .handleError()
            .eraseToAnyPublisher()
    }
    
    func getLatestMoviesInCollection(collectionId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        Const.session.request(CollectionsService.getMoviesInCollectionWithFilter(collectionId: collectionId, page: page, filter: "last"))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(CollectionsParser.parseMoviesInCollection)
            .handleError()
            .eraseToAnyPublisher()
    }
    
    func getSoonMoviesInCollection(collectionId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        Const.session.request(CollectionsService.getMoviesInCollectionWithFilter(collectionId: collectionId, page: page, filter: "soon"))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(CollectionsParser.parseMoviesInCollection)
            .handleError()
            .eraseToAnyPublisher()
    }
}
