import Combine
import Dependencies

struct GetCommentUseCase {
    @Dependency(\.movieDetailsRepository) private var repository

    func callAsFunction(movieId: String, commentId: String) -> AnyPublisher<Comment, Error> {
        repository.getComment(movieId: movieId, commentId: commentId)
    }
}

extension GetCommentUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var getCommentUseCase: GetCommentUseCase {
        get { self[GetCommentUseCase.self] }
        set { self[GetCommentUseCase.self] = newValue }
    }
}
