import Dependencies

protocol CollectionsRepository: Sendable {
    func getCollections(page: Int) async throws -> [MoviesCollection]

    func getMoviesInCollection(collectionId: String, filter: Filters, page: Int) async throws -> [MovieSimple]
}

private enum CollectionsRepositoryKey: DependencyKey {
    static let liveValue: any CollectionsRepository = CollectionsRepositoryImpl()
}

extension DependencyValues {
    var collectionsRepository: any CollectionsRepository {
        get { self[CollectionsRepositoryKey.self] }
        set { self[CollectionsRepositoryKey.self] = newValue }
    }
}
