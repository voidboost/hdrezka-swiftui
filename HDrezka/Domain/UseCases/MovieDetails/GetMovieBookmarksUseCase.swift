import Combine

struct GetMovieBookmarksUseCase {
    private let repository: MovieDetailsRepository

    init(repository: MovieDetailsRepository) {
        self.repository = repository
    }

    func callAsFunction(movieId: String) -> AnyPublisher<[Bookmark], Error> {
        repository.getMovieBookmarks(movieId: movieId)
    }
}
