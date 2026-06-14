import Combine

struct GetLatestMoviesByCountryUseCase {
    private let repository: MovieListsRepository

    init(repository: MovieListsRepository) {
        self.repository = repository
    }

    func callAsFunction(countryId: String, genre: Int, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        repository.getLatestMoviesByCountry(countryId: countryId, genre: genre, page: page)
    }
}
