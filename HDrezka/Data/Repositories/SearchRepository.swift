import Alamofire
import Combine
import Foundation

protocol SearchRepository {
    func search(query: String, page: Int) -> AnyPublisher<[MovieSimple], Error>

    func categories() -> AnyPublisher<[MovieType], Error>
}

struct SearchRepositoryImpl: SearchRepository {
    func search(query: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        Const.session.request(SearchService.search(query: query, page: page))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(SearchParser.parseSearch)
            .handleError()
            .eraseToAnyPublisher()
    }

    func categories() -> AnyPublisher<[MovieType], Error> {
        Const.session.request(SearchService.categories)
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(SearchParser.parseCategories)
            .handleError()
            .eraseToAnyPublisher()
    }
}
