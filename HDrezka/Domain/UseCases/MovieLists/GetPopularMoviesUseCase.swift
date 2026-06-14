import Combine

struct GetPopularMoviesUseCase {
    private let repository: MovieListsRepository

    init(repository: MovieListsRepository) {
        self.repository = repository
    }

    func callAsFunction(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error> {
        repository.getPopularMovies(page: page, genre: genre)
    }
}
