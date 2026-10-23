import Dependencies

struct GetLatestMoviesByCountryUseCase {
    @Dependency(\.movieListsRepository) private var repository

    func callAsFunction(countryId: String, genre: Int, page: Int) async throws -> [MovieSimple] {
        try await repository.getLatestMoviesByCountry(countryId: countryId, genre: genre, page: page)
    }
}

extension GetLatestMoviesByCountryUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var getLatestMoviesByCountryUseCase: GetLatestMoviesByCountryUseCase {
        get { self[GetLatestMoviesByCountryUseCase.self] }
        set { self[GetLatestMoviesByCountryUseCase.self] = newValue }
    }
}
