import Combine

struct ToggleLikeCommentUseCase {
    private let repository: MovieDetailsRepository

    init(repository: MovieDetailsRepository) {
        self.repository = repository
    }

    func callAsFunction(id: String) -> AnyPublisher<(Int, Bool), Error> {
        repository.toggleLikeComment(id: id)
    }
}
