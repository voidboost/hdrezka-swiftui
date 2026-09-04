import Combine
import Dependencies

struct GetSoonMoviesByCountryUseCase {
    @Dependency(\.movieListsRepository) private var repository

    func callAsFunction(countryId: String, genre: Int, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        repository.getSoonMoviesByCountry(countryId: countryId, genre: genre, page: page)
    }
}

extension GetSoonMoviesByCountryUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var getSoonMoviesByCountryUseCase: GetSoonMoviesByCountryUseCase {
        get { self[GetSoonMoviesByCountryUseCase.self] }
        set { self[GetSoonMoviesByCountryUseCase.self] = newValue }
    }
}
