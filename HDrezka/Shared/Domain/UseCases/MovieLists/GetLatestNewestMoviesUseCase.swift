import Combine

struct GetLatestNewestMoviesUseCase {
    private let repository: MovieListsRepository

    init(repository: MovieListsRepository) {
        self.repository = repository
    }

    func callAsFunction(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error> {
        repository.getLatestNewestMovies(page: page, genre: genre)
    }
}
