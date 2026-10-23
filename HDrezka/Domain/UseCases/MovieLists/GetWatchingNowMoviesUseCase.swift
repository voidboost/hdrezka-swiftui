import Dependencies

struct GetWatchingNowMoviesUseCase {
    @Dependency(\.movieListsRepository) private var repository

    func callAsFunction(page: Int, genre: Int) async throws -> [MovieSimple] {
        try await repository.getWatchingNowMovies(page: page, genre: genre)
    }
}

extension GetWatchingNowMoviesUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var getWatchingNowMoviesUseCase: GetWatchingNowMoviesUseCase {
        get { self[GetWatchingNowMoviesUseCase.self] }
        set { self[GetWatchingNowMoviesUseCase.self] = newValue }
    }
}
