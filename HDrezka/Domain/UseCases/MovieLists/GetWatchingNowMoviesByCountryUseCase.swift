import Combine
import Dependencies

struct GetWatchingNowMoviesByCountryUseCase {
    @Dependency(\.movieListsRepository) private var repository

    func callAsFunction(countryId: String, genre: Int, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        repository.getWatchingNowMoviesByCountry(countryId: countryId, genre: genre, page: page)
    }
}

extension GetWatchingNowMoviesByCountryUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var getWatchingNowMoviesByCountryUseCase: GetWatchingNowMoviesByCountryUseCase {
        get { self[GetWatchingNowMoviesByCountryUseCase.self] }
        set { self[GetWatchingNowMoviesByCountryUseCase.self] = newValue }
    }
}
