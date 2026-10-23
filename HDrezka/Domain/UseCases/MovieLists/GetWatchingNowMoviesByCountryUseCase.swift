import Dependencies

struct GetWatchingNowMoviesByCountryUseCase {
    @Dependency(\.movieListsRepository) private var repository

    func callAsFunction(countryId: String, genre: Int, page: Int) async throws -> [MovieSimple] {
        try await repository.getWatchingNowMoviesByCountry(countryId: countryId, genre: genre, page: page)
    }
}

extension GetWatchingNowMoviesByCountryUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var getWatchingNowMoviesByCountryUseCase: GetWatchingNowMoviesByCountryUseCase {
        get { self[GetWatchingNowMoviesByCountryUseCase.self] }
        set { self[GetWatchingNowMoviesByCountryUseCase.self] = newValue }
    }
}
