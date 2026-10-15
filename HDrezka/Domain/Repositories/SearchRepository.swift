import Combine
import Dependencies

protocol SearchRepository: Sendable {
    func search(query: String, page: Int) -> AnyPublisher<[MovieSimple], Error>

    func categories() -> AnyPublisher<[MovieType], Error>
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
