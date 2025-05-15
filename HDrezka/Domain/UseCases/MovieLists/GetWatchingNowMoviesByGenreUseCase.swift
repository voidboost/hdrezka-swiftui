import Combine

struct GetWatchingNowMoviesByGenreUseCase {
    private let repository: MovieListsRepository

    init(repository: MovieListsRepository) {
        self.repository = repository
    }

    func callAsFunction(genreId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        repository.getWatchingNowMoviesByGenre(genreId: genreId, page: page)
    }
}
