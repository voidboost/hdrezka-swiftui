import Dependencies

struct DeleteBookmarksCategoryUseCase {
    @Dependency(\.accountRepository) private var repository

    func callAsFunction(id: Int) async throws -> Bool {
        try await repository.deleteBookmarksCategory(id: id)
    }
}

extension DeleteBookmarksCategoryUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var deleteBookmarksCategoryUseCase: DeleteBookmarksCategoryUseCase {
        get { self[DeleteBookmarksCategoryUseCase.self] }
        set { self[DeleteBookmarksCategoryUseCase.self] = newValue }
    }
}
