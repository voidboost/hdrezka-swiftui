import Dependencies

struct RemoveFromBookmarksUseCase {
    @Dependency(\.accountRepository) private var repository

    func callAsFunction(movies: [String], bookmarkUserCategory: Int) async throws -> Bool {
        try await repository.removeFromBookmarks(movies: movies, bookmarkUserCategory: bookmarkUserCategory)
    }
}

extension RemoveFromBookmarksUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var removeFromBookmarksUseCase: RemoveFromBookmarksUseCase {
        get { self[RemoveFromBookmarksUseCase.self] }
        set { self[RemoveFromBookmarksUseCase.self] = newValue }
    }
}
