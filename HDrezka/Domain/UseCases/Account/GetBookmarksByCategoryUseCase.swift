import Dependencies

struct GetBookmarksByCategoryUseCase {
    @Dependency(\.accountRepository) private var repository

    func callAsFunction(id: Int, filter: BookmarkFilters, genre: Int, page: Int) async throws -> [MovieSimple] {
        try await repository.getBookmarksByCategory(id: id, filter: filter, genre: genre, page: page)
    }
}

extension GetBookmarksByCategoryUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var getBookmarksByCategoryUseCase: GetBookmarksByCategoryUseCase {
        get { self[GetBookmarksByCategoryUseCase.self] }
        set { self[GetBookmarksByCategoryUseCase.self] = newValue }
    }
}
