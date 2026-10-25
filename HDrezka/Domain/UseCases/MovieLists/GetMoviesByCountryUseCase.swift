import Dependencies

struct GetMoviesByCountryUseCase {
    @Dependency(\.movieListsRepository) private var repository

    func callAsFunction(countryId: String, filter: Filters, genre: Int, page: Int) async throws -> [MovieSimple] {
        try await repository.getMoviesByCountry(countryId: countryId, filter: filter, genre: genre, page: page)
    }
}

extension GetMoviesByCountryUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var getMoviesByCountryUseCase: GetMoviesByCountryUseCase {
        get { self[GetMoviesByCountryUseCase.self] }
        set { self[GetMoviesByCountryUseCase.self] = newValue }
    }
}
