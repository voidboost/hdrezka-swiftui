import Combine

struct GetPopularMoviesByGenreUseCase {
    private let repository: MovieListsRepository

    init(repository: MovieListsRepository) {
        self.repository = repository
    }

    func callAsFunction(genreId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        repository.getPopularMoviesByGenre(genreId: genreId, page: page)
    }
}
