import Dependencies

struct GetWatchingNowMoviesInCollectionUseCase {
    @Dependency(\.collectionsRepository) private var repository

    func callAsFunction(collectionId: String, page: Int) async throws -> [MovieSimple] {
        try await repository.getWatchingNowMoviesInCollection(collectionId: collectionId, page: page)
    }
}

extension GetWatchingNowMoviesInCollectionUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var getWatchingNowMoviesInCollectionUseCase: GetWatchingNowMoviesInCollectionUseCase {
        get { self[GetWatchingNowMoviesInCollectionUseCase.self] }
        set { self[GetWatchingNowMoviesInCollectionUseCase.self] = newValue }
    }
}
