import Dependencies

struct GetBookmarksByCategoryPopularUseCase {
    @Dependency(\.accountRepository) private var repository

    func callAsFunction(id: Int, genre: Int, page: Int) async throws -> [MovieSimple] {
        try await repository.getBookmarksByCategoryPopular(id: id, genre: genre, page: page)
    }
}

extension GetBookmarksByCategoryPopularUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var getBookmarksByCategoryPopularUseCase: GetBookmarksByCategoryPopularUseCase {
        get { self[GetBookmarksByCategoryPopularUseCase.self] }
        set { self[GetBookmarksByCategoryPopularUseCase.self] = newValue }
    }
}
