import Alamofire
import Dependencies
import Foundation

struct SearchRepositoryImpl: SearchRepository {
    @Dependency(\.session) private var session

    func search(query: String, page: Int) async throws -> [MovieSimple] {
        try await session.page(SearchService.search(query: query, page: page), parse: MovieListsParser.parseMovies)
    }

    func categories() async throws -> [MovieType] {
        try await session.page(SearchService.categories, parse: SearchParser.parseCategories)
    }
}
