import Dependencies

struct GetBookmarksUseCase {
    @Dependency(\.accountRepository) private var repository

    func callAsFunction() async throws -> [Bookmark] {
        try await repository.getBookmarks()
    }
}

extension GetBookmarksUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var getBookmarksUseCase: GetBookmarksUseCase {
        get { self[GetBookmarksUseCase.self] }
        set { self[GetBookmarksUseCase.self] = newValue }
    }
}
