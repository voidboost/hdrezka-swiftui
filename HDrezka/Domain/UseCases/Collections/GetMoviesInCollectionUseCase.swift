import Dependencies

struct GetMoviesInCollectionUseCase {
    @Dependency(\.collectionsRepository) private var repository

    func callAsFunction(collectionId: String, filter: Filters, page: Int) async throws -> [MovieSimple] {
        try await repository.getMoviesInCollection(collectionId: collectionId, filter: filter, page: page)
    }
}

extension GetMoviesInCollectionUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var getMoviesInCollectionUseCase: GetMoviesInCollectionUseCase {
        get { self[GetMoviesInCollectionUseCase.self] }
        set { self[GetMoviesInCollectionUseCase.self] = newValue }
    }
}
