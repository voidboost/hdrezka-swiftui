import Dependencies

struct GetPopularMoviesByCountryUseCase {
    @Dependency(\.movieListsRepository) private var repository

    func callAsFunction(countryId: String, genre: Int, page: Int) async throws -> [MovieSimple] {
        try await repository.getPopularMoviesByCountry(countryId: countryId, genre: genre, page: page)
    }
}

extension GetPopularMoviesByCountryUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var getPopularMoviesByCountryUseCase: GetPopularMoviesByCountryUseCase {
        get { self[GetPopularMoviesByCountryUseCase.self] }
        set { self[GetPopularMoviesByCountryUseCase.self] = newValue }
    }
}
