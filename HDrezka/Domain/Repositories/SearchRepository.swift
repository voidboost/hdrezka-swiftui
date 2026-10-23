import Dependencies

protocol SearchRepository: Sendable {
    func search(query: String, page: Int) async throws -> [MovieSimple]

    func categories() async throws -> [MovieType]
}

private enum SearchRepositoryKey: DependencyKey {
    static let liveValue: any SearchRepository = SearchRepositoryImpl()
}

extension DependencyValues {
    var searchRepository: any SearchRepository {
        get { self[SearchRepositoryKey.self] }
        set { self[SearchRepositoryKey.self] = newValue }
    }
}
