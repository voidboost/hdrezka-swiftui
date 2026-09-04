import Combine
import Dependencies

struct SendCommentUseCase {
    @Dependency(\.movieDetailsRepository) private var repository

    func callAsFunction(id: String?, postId: String, name: String?, text: String, adb: String?, type: String?) -> AnyPublisher<SendCommentResult, Error> {
        repository.sendComment(id: id, postId: postId, name: name, text: text, adb: adb, type: type)
    }
}

extension SendCommentUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var sendCommentUseCase: SendCommentUseCase {
        get { self[SendCommentUseCase.self] }
        set { self[SendCommentUseCase.self] = newValue }
    }
}
