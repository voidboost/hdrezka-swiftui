import Dependencies

struct GetMovieBookmarksUseCase {
    @Dependency(\.movieDetailsRepository) private var repository

    func callAsFunction(movieId: String) async throws -> [Bookmark] {
        try await repository.getMovieBookmarks(movieId: movieId)
    }
}

extension GetMovieBookmarksUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var getMovieBookmarksUseCase: GetMovieBookmarksUseCase {
        get { self[GetMovieBookmarksUseCase.self] }
        set { self[GetMovieBookmarksUseCase.self] = newValue }
    }
}
