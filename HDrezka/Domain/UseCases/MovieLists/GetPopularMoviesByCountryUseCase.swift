import Combine
import Dependencies

struct GetPopularMoviesByCountryUseCase {
    @Dependency(\.movieListsRepository) private var repository

    func callAsFunction(countryId: String, genre: Int, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        repository.getPopularMoviesByCountry(countryId: countryId, genre: genre, page: page)
    }
}

extension GetPopularMoviesByCountryUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var getPopularMoviesByCountryUseCase: GetPopularMoviesByCountryUseCase {
        get { self[GetPopularMoviesByCountryUseCase.self] }
        set { self[GetPopularMoviesByCountryUseCase.self] = newValue }
    }
}
