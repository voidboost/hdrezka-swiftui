import Combine

struct GetPopularNewestMoviesUseCase {
    private let repository: MovieListsRepository

    init(repository: MovieListsRepository) {
        self.repository = repository
    }

    func callAsFunction(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error> {
        repository.getPopularNewestMovies(page: page, genre: genre)
    }
}
