import Dependencies

struct GetWatchingNowNewestMoviesUseCase {
    @Dependency(\.movieListsRepository) private var repository

    func callAsFunction(page: Int, genre: Int) async throws -> [MovieSimple] {
        try await repository.getWatchingNowNewestMovies(page: page, genre: genre)
    }
}

extension GetWatchingNowNewestMoviesUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var getWatchingNowNewestMoviesUseCase: GetWatchingNowNewestMoviesUseCase {
        get { self[GetWatchingNowNewestMoviesUseCase.self] }
        set { self[GetWatchingNowNewestMoviesUseCase.self] = newValue }
    }
}
