import Dependencies

struct SearchUseCase {
    @Dependency(\.searchRepository) private var repository

    func callAsFunction(query: String, page: Int) async throws -> [MovieSimple] {
        try await repository.search(query: query, page: page)
    }
}

extension SearchUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var searchUseCase: SearchUseCase {
        get { self[SearchUseCase.self] }
        set { self[SearchUseCase.self] = newValue }
    }
}
