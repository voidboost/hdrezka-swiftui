import Dependencies

struct GetCommentsPageUseCase {
    @Dependency(\.movieDetailsRepository) private var repository

    func callAsFunction(movieId: String, page: Int) async throws -> [Comment] {
        try await repository.getCommentsPage(movieId: movieId, page: page)
    }
}

extension GetCommentsPageUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var getCommentsPageUseCase: GetCommentsPageUseCase {
        get { self[GetCommentsPageUseCase.self] }
        set { self[GetCommentsPageUseCase.self] = newValue }
    }
}
