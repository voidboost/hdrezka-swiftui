import Dependencies

struct GetMovieListUseCase {
    @Dependency(\.movieListsRepository) private var repository

    func callAsFunction(listId: String, page: Int) async throws -> (String, [MovieSimple]) {
        try await repository.getMovieList(listId: listId, page: page)
    }
}

extension GetMovieListUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var getMovieListUseCase: GetMovieListUseCase {
        get { self[GetMovieListUseCase.self] }
        set { self[GetMovieListUseCase.self] = newValue }
    }
}
