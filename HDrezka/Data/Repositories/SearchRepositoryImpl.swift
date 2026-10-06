import Alamofire
import Combine
import Dependencies
import Foundation

struct SearchRepositoryImpl: SearchRepository {
    @Dependency(\.session) private var session

    func search(query: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        session.string(SearchService.search(query: query, page: page), parse: SearchParser.parseSearch)
    }

    func categories() -> AnyPublisher<[MovieType], Error> {
        session.string(SearchService.categories, parse: SearchParser.parseCategories)
    }
}
