import Dependencies

struct ToggleLikeCommentUseCase {
    @Dependency(\.movieDetailsRepository) private var repository

    func callAsFunction(id: String) async throws -> (Int, Bool) {
        try await repository.toggleLikeComment(id: id)
    }
}

extension ToggleLikeCommentUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var toggleLikeCommentUseCase: ToggleLikeCommentUseCase {
        get { self[ToggleLikeCommentUseCase.self] }
        set { self[ToggleLikeCommentUseCase.self] = newValue }
    }
}
