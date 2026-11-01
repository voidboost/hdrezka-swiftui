import Alamofire
import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct SearchClient: Sendable {
    var search: @Sendable (_ query: String, _ page: Int) async throws -> [MovieSimple]
    var categories: @Sendable () async throws -> [MovieType]
}

extension SearchClient: DependencyKey {
    static let liveValue: Self = {
        @Dependency(\.session) var session

        return Self(
            search: { query, page in
                try await session.page(SearchService.search(query: query, page: page), parse: MovieListsParser.parseMovies)
            },
            categories: {
                try await session.page(SearchService.categories, parse: SearchParser.parseCategories)
            }
        )
    }()
}

extension DependencyValues {
    var searchClient: SearchClient {
        get { self[SearchClient.self] }
        set { self[SearchClient.self] = newValue }
    }
}
