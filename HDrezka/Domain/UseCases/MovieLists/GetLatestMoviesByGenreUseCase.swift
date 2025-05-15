import Combine

struct GetLatestMoviesByGenreUseCase {
    private let repository: MovieListsRepository

    init(repository: MovieListsRepository) {
        self.repository = repository
    }

    func callAsFunction(genreId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        repository.getLatestMoviesByGenre(genreId: genreId, page: page)
    }
}
