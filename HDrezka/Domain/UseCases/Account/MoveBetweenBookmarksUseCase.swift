import Dependencies

struct MoveBetweenBookmarksUseCase {
    @Dependency(\.accountRepository) private var repository

    func callAsFunction(movies: [String], fromBookmarkUserCategory: Int, toBookmarkUserCategory: Int) async throws -> Int {
        try await repository.moveBetweenBookmarks(movies: movies, fromBookmarkUserCategory: fromBookmarkUserCategory, toBookmarkUserCategory: toBookmarkUserCategory)
    }
}

extension MoveBetweenBookmarksUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var moveBetweenBookmarksUseCase: MoveBetweenBookmarksUseCase {
        get { self[MoveBetweenBookmarksUseCase.self] }
        set { self[MoveBetweenBookmarksUseCase.self] = newValue }
    }
}
