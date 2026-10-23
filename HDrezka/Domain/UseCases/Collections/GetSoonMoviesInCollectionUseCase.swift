import Dependencies

struct GetSoonMoviesInCollectionUseCase {
    @Dependency(\.collectionsRepository) private var repository

    func callAsFunction(collectionId: String, page: Int) async throws -> [MovieSimple] {
        try await repository.getSoonMoviesInCollection(collectionId: collectionId, page: page)
    }
}

extension GetSoonMoviesInCollectionUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var getSoonMoviesInCollectionUseCase: GetSoonMoviesInCollectionUseCase {
        get { self[GetSoonMoviesInCollectionUseCase.self] }
        set { self[GetSoonMoviesInCollectionUseCase.self] = newValue }
    }
}
