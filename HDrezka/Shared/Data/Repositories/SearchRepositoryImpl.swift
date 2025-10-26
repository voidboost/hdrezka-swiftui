import Alamofire
import Combine
import FactoryKit
import Foundation

struct SearchRepositoryImpl: SearchRepository {
    @Injected(\.session) private var session

    func search(query: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        session.request(SearchService.search(query: query, page: page))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(SearchParser.parseSearch)
            .handleError()
            .eraseToAnyPublisher()
    }

    func categories() -> AnyPublisher<[MovieType], Error> {
        session.request(SearchService.categories)
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(SearchParser.parseCategories)
            .handleError()
            .eraseToAnyPublisher()
    }
}
