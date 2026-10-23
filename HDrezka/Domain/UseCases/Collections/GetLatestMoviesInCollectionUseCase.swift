import Dependencies

struct GetLatestMoviesInCollectionUseCase {
    @Dependency(\.collectionsRepository) private var repository

    func callAsFunction(collectionId: String, page: Int) async throws -> [MovieSimple] {
        try await repository.getLatestMoviesInCollection(collectionId: collectionId, page: page)
    }
}

extension GetLatestMoviesInCollectionUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var getLatestMoviesInCollectionUseCase: GetLatestMoviesInCollectionUseCase {
        get { self[GetLatestMoviesInCollectionUseCase.self] }
        set { self[GetLatestMoviesInCollectionUseCase.self] = newValue }
    }
}
