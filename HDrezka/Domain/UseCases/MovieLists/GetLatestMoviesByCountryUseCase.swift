import Combine
import Dependencies

struct GetLatestMoviesByCountryUseCase {
    @Dependency(\.movieListsRepository) private var repository

    func callAsFunction(countryId: String, genre: Int, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        repository.getLatestMoviesByCountry(countryId: countryId, genre: genre, page: page)
    }
}

extension GetLatestMoviesByCountryUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var getLatestMoviesByCountryUseCase: GetLatestMoviesByCountryUseCase {
        get { self[GetLatestMoviesByCountryUseCase.self] }
        set { self[GetLatestMoviesByCountryUseCase.self] = newValue }
    }
}
