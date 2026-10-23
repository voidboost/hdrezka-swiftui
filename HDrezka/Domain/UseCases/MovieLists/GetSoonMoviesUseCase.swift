import Dependencies

struct GetSoonMoviesUseCase {
    @Dependency(\.movieListsRepository) private var repository

    func callAsFunction(page: Int, genre: Int) async throws -> [MovieSimple] {
        try await repository.getSoonMovies(page: page, genre: genre)
    }
}

extension GetSoonMoviesUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var getSoonMoviesUseCase: GetSoonMoviesUseCase {
        get { self[GetSoonMoviesUseCase.self] }
        set { self[GetSoonMoviesUseCase.self] = newValue }
    }
}
