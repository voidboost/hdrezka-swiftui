import Combine

struct GetWatchingLaterMoviesUseCase {
    private let repository: AccountRepository

    init(repository: AccountRepository) {
        self.repository = repository
    }

    func callAsFunction() -> AnyPublisher<[MovieWatchLater], Error> {
        repository.getWatchingLaterMovies()
    }
}
