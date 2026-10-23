import Dependencies

struct GetLatestMoviesByGenreUseCase {
    @Dependency(\.movieListsRepository) private var repository

    func callAsFunction(genreId: String, page: Int) async throws -> [MovieSimple] {
        try await repository.getLatestMoviesByGenre(genreId: genreId, page: page)
    }
}

extension GetLatestMoviesByGenreUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var getLatestMoviesByGenreUseCase: GetLatestMoviesByGenreUseCase {
        get { self[GetLatestMoviesByGenreUseCase.self] }
        set { self[GetLatestMoviesByGenreUseCase.self] = newValue }
    }
}
