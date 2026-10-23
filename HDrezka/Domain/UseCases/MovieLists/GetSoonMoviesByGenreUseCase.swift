import Dependencies

struct GetSoonMoviesByGenreUseCase {
    @Dependency(\.movieListsRepository) private var repository

    func callAsFunction(genreId: String, page: Int) async throws -> [MovieSimple] {
        try await repository.getSoonMoviesByGenre(genreId: genreId, page: page)
    }
}

extension GetSoonMoviesByGenreUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var getSoonMoviesByGenreUseCase: GetSoonMoviesByGenreUseCase {
        get { self[GetSoonMoviesByGenreUseCase.self] }
        set { self[GetSoonMoviesByGenreUseCase.self] = newValue }
    }
}
