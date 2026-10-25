import Alamofire
import Dependencies
import Foundation

struct CollectionsRepositoryImpl: CollectionsRepository {
    @Dependency(\.session) private var session

    func getCollections(page: Int) async throws -> [MoviesCollection] {
        try await session.string(CollectionsService.getCollections(page: page), parse: CollectionsParser.parseCollections)
    }

    func getMoviesInCollection(collectionId: String, filter: Filters, page: Int) async throws -> [MovieSimple] {
        try await session.string(CollectionsService.getMoviesInCollectionWithFilter(collectionId: collectionId, page: page, filter: filter.query), parse: MovieListsParser.parseMovies)
    }
}
