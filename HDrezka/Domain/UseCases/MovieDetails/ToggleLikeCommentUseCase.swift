import Combine
import Dependencies

struct ToggleLikeCommentUseCase {
    @Dependency(\.movieDetailsRepository) private var repository

    func callAsFunction(id: String) -> AnyPublisher<(Int, Bool), Error> {
        repository.toggleLikeComment(id: id)
    }
}

extension ToggleLikeCommentUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var toggleLikeCommentUseCase: ToggleLikeCommentUseCase {
        get { self[ToggleLikeCommentUseCase.self] }
        set { self[ToggleLikeCommentUseCase.self] = newValue }
    }
}
