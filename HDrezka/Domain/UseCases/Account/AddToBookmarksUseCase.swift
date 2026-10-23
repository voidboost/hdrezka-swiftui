import Dependencies

struct AddToBookmarksUseCase {
    @Dependency(\.accountRepository) private var repository

    func callAsFunction(movieId: String, bookmarkUserCategory: Int) async throws -> Bool {
        try await repository.addToBookmarks(movieId: movieId, bookmarkUserCategory: bookmarkUserCategory)
    }
}

extension AddToBookmarksUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var addToBookmarksUseCase: AddToBookmarksUseCase {
        get { self[AddToBookmarksUseCase.self] }
        set { self[AddToBookmarksUseCase.self] = newValue }
    }
}
