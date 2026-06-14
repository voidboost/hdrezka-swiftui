import Combine

struct GetMovieDetailsUseCase {
    private let repository: MovieDetailsRepository

    init(repository: MovieDetailsRepository) {
        self.repository = repository
    }

    func callAsFunction(movieId: String) -> AnyPublisher<MovieDetailed, Error> {
        repository.getMovieDetails(movieId: movieId)
    }
}
