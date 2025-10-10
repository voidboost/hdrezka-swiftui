import Combine

struct GetCommentUseCase {
    private let repository: MovieDetailsRepository

    init(repository: MovieDetailsRepository) {
        self.repository = repository
    }

    func callAsFunction(movieId: String, commentId: String) -> AnyPublisher<Comment, Error> {
        repository.getComment(movieId: movieId, commentId: commentId)
    }
}
