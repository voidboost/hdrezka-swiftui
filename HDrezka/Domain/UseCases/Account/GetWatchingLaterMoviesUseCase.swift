import Dependencies

struct GetWatchingLaterMoviesUseCase {
    @Dependency(\.accountRepository) private var repository

    func callAsFunction() async throws -> [MovieWatchLater] {
        try await repository.getWatchingLaterMovies()
    }
}

extension GetWatchingLaterMoviesUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var getWatchingLaterMoviesUseCase: GetWatchingLaterMoviesUseCase {
        get { self[GetWatchingLaterMoviesUseCase.self] }
        set { self[GetWatchingLaterMoviesUseCase.self] = newValue }
    }
}
