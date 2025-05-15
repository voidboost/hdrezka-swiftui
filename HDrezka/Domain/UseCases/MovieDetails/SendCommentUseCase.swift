import Combine

struct SendCommentUseCase {
    private let repository: MovieDetailsRepository

    init(repository: MovieDetailsRepository) {
        self.repository = repository
    }

    func callAsFunction(id: String?, postId: String, name: String?, text: String, adb: String?, type: String?) -> AnyPublisher<(Bool, Bool, String), Error> {
        repository.sendComment(id: id, postId: postId, name: name, text: text, adb: adb, type: type)
    }
}
