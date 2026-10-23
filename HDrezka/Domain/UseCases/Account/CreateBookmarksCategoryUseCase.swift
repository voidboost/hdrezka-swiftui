import Dependencies

struct CreateBookmarksCategoryUseCase {
    @Dependency(\.accountRepository) private var repository

    func callAsFunction(name: String) async throws -> Bookmark {
        try await repository.createBookmarksCategory(name: name)
    }
}

extension CreateBookmarksCategoryUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var createBookmarksCategoryUseCase: CreateBookmarksCategoryUseCase {
        get { self[CreateBookmarksCategoryUseCase.self] }
        set { self[CreateBookmarksCategoryUseCase.self] = newValue }
    }
}
