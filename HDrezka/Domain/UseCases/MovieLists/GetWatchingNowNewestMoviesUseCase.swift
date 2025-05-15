import Combine

struct GetWatchingNowNewestMoviesUseCase {
    private let repository: MovieListsRepository

    init(repository: MovieListsRepository) {
        self.repository = repository
    }

    func callAsFunction(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error> {
        repository.getWatchingNowNewestMovies(page: page, genre: genre)
    }
}
