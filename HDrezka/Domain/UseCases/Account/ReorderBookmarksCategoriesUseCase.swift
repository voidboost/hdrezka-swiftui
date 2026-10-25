import Dependencies

struct ReorderBookmarksCategoriesUseCase {
    @Dependency(\.accountRepository) private var repository

    func callAsFunction(newOrder: [Bookmark]) async throws {
        try await repository.reorderBookmarksCategories(newOrder: newOrder)
    }
}

extension ReorderBookmarksCategoriesUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var reorderBookmarksCategoriesUseCase: ReorderBookmarksCategoriesUseCase {
        get { self[ReorderBookmarksCategoriesUseCase.self] }
        set { self[ReorderBookmarksCategoriesUseCase.self] = newValue }
    }
}
