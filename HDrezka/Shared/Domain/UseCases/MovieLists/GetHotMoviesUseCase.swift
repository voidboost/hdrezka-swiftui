import Combine

struct GetHotMoviesUseCase {
    private let repository: MovieListsRepository

    init(repository: MovieListsRepository) {
        self.repository = repository
    }

    func callAsFunction(genre: Int) -> AnyPublisher<[MovieSimple], Error> {
        repository.getHotMovies(genre: genre)
    }
}
