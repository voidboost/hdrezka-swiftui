import Combine

struct GetMovieTrailerIdUseCase {
    private let repository: MovieDetailsRepository

    init(repository: MovieDetailsRepository) {
        self.repository = repository
    }

    func callAsFunction(movieId: String) -> AnyPublisher<String, Error> {
        repository.getMovieTrailerId(movieId: movieId)
    }
}
