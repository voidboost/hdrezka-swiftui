import Dependencies

struct GetMoviesUseCase {
    @Dependency(\.movieListsRepository) private var repository

    func callAsFunction(filter: Filters, genre: Int, page: Int) async throws -> [MovieSimple] {
        try await repository.getMovies(filter: filter, genre: genre, page: page)
    }
}

extension GetMoviesUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var getMoviesUseCase: GetMoviesUseCase {
        get { self[GetMoviesUseCase.self] }
        set { self[GetMoviesUseCase.self] = newValue }
    }
}
