import Dependencies

struct GetNewestMoviesUseCase {
    @Dependency(\.movieListsRepository) private var repository

    func callAsFunction(filter: NewFilters, genre: Int, page: Int) async throws -> [MovieSimple] {
        try await repository.getNewestMovies(filter: filter, genre: genre, page: page)
    }
}

extension GetNewestMoviesUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var getNewestMoviesUseCase: GetNewestMoviesUseCase {
        get { self[GetNewestMoviesUseCase.self] }
        set { self[GetNewestMoviesUseCase.self] = newValue }
    }
}
