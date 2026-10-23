import Dependencies

struct DeleteCommentUseCase {
    @Dependency(\.movieDetailsRepository) private var repository

    func callAsFunction(id: String, hash: String) async throws -> (Bool, String?) {
        try await repository.deleteComment(id: id, hash: hash)
    }
}

extension DeleteCommentUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var deleteCommentUseCase: DeleteCommentUseCase {
        get { self[DeleteCommentUseCase.self] }
        set { self[DeleteCommentUseCase.self] = newValue }
    }
}
