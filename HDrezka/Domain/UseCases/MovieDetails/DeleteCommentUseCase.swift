import Combine
import Dependencies

struct DeleteCommentUseCase {
    @Dependency(\.movieDetailsRepository) private var repository

    func callAsFunction(id: String, hash: String) -> AnyPublisher<(Bool, String?), Error> {
        repository.deleteComment(id: id, hash: hash)
    }
}

extension DeleteCommentUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var deleteCommentUseCase: DeleteCommentUseCase {
        get { self[DeleteCommentUseCase.self] }
        set { self[DeleteCommentUseCase.self] = newValue }
    }
}
