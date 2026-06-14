import Combine

struct GetPopularMoviesByCountryUseCase {
    private let repository: MovieListsRepository

    init(repository: MovieListsRepository) {
        self.repository = repository
    }

    func callAsFunction(countryId: String, genre: Int, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        repository.getPopularMoviesByCountry(countryId: countryId, genre: genre, page: page)
    }
}
