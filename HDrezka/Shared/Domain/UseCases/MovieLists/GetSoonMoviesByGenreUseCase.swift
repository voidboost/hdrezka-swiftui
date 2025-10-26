import Combine

struct GetSoonMoviesByGenreUseCase {
    private let repository: MovieListsRepository

    init(repository: MovieListsRepository) {
        self.repository = repository
    }

    func callAsFunction(genreId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        repository.getSoonMoviesByGenre(genreId: genreId, page: page)
    }
}
