import Alamofire
import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct CollectionsClient: Sendable {
    var getCollections: @Sendable (_ page: Int) async throws -> [MoviesCollection]
    var getMoviesInCollection: @Sendable (_ collectionId: String, _ filter: Filters, _ page: Int) async throws -> [MovieSimple]
}

extension CollectionsClient: DependencyKey {
    static let liveValue: Self = {
        @Dependency(\.session) var session

        return Self(
            getCollections: { page in
                try await session.page(CollectionsService.getCollections(page: page), parse: CollectionsParser.parseCollections)
            },
            getMoviesInCollection: { collectionId, filter, page in
                try await session.page(CollectionsService.getMoviesInCollectionWithFilter(collectionId: collectionId, page: page, filter: filter.query), parse: MovieListsParser.parseMovies)
            }
        )
    }()
}

extension DependencyValues {
    var collectionsClient: CollectionsClient {
        get { self[CollectionsClient.self] }
        set { self[CollectionsClient.self] = newValue }
    }
}
