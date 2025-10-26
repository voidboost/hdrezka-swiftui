import Combine

struct GetMovieThumbnailsUseCase {
    private let repository: MovieDetailsRepository

    init(repository: MovieDetailsRepository) {
        self.repository = repository
    }

    func callAsFunction(path: String) -> AnyPublisher<WebVTT, Error> {
        repository.getMovieThumbnails(path: path)
    }
}
