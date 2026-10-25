import Dependencies

struct GetMoviesByGenreUseCase {
    @Dependency(\.movieListsRepository) private var repository

    func callAsFunction(genreId: String, filter: Filters, page: Int) async throws -> [MovieSimple] {
        try await repository.getMoviesByGenre(genreId: genreId, filter: filter, page: page)
    }
}

extension GetMoviesByGenreUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var getMoviesByGenreUseCase: GetMoviesByGenreUseCase {
        get { self[GetMoviesByGenreUseCase.self] }
        set { self[GetMoviesByGenreUseCase.self] = newValue }
    }
}
