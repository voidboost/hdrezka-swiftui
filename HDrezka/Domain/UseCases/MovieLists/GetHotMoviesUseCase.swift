import Dependencies

struct GetHotMoviesUseCase {
    @Dependency(\.movieListsRepository) private var repository

    func callAsFunction(genre: Int) async throws -> [MovieSimple] {
        try await repository.getHotMovies(genre: genre)
    }
}

extension GetHotMoviesUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var getHotMoviesUseCase: GetHotMoviesUseCase {
        get { self[GetHotMoviesUseCase.self] }
        set { self[GetHotMoviesUseCase.self] = newValue }
    }
}
