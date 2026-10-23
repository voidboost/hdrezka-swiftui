import Dependencies

struct GetPopularMoviesInCollectionUseCase {
    @Dependency(\.collectionsRepository) private var repository

    func callAsFunction(collectionId: String, page: Int) async throws -> [MovieSimple] {
        try await repository.getPopularMoviesInCollection(collectionId: collectionId, page: page)
    }
}

extension GetPopularMoviesInCollectionUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var getPopularMoviesInCollectionUseCase: GetPopularMoviesInCollectionUseCase {
        get { self[GetPopularMoviesInCollectionUseCase.self] }
        set { self[GetPopularMoviesInCollectionUseCase.self] = newValue }
    }
}
