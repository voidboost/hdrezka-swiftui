import Combine

struct DeleteCommentUseCase {
    private let repository: MovieDetailsRepository

    init(repository: MovieDetailsRepository) {
        self.repository = repository
    }

    func callAsFunction(id: String, hash: String) -> AnyPublisher<(Bool, String?), Error> {
        repository.deleteComment(id: id, hash: hash)
    }
}
