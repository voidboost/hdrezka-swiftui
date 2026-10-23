import Dependencies

struct GetBookmarksByCategoryYearUseCase {
    @Dependency(\.accountRepository) private var repository

    func callAsFunction(id: Int, genre: Int, page: Int) async throws -> [MovieSimple] {
        try await repository.getBookmarksByCategoryYear(id: id, genre: genre, page: page)
    }
}

extension GetBookmarksByCategoryYearUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var getBookmarksByCategoryYearUseCase: GetBookmarksByCategoryYearUseCase {
        get { self[GetBookmarksByCategoryYearUseCase.self] }
        set { self[GetBookmarksByCategoryYearUseCase.self] = newValue }
    }
}
