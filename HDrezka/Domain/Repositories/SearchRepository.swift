import Combine
import Dependencies

protocol SearchRepository {
    func search(query: String, page: Int) -> AnyPublisher<[MovieSimple], Error>

    func categories() -> AnyPublisher<[MovieType], Error>
}

private enum SearchRepositoryKey: DependencyKey {
    static var liveValue: any SearchRepository = SearchRepositoryImpl()
}

extension DependencyValues {
    var searchRepository: any SearchRepository {
        get { self[SearchRepositoryKey.self] }
        set { self[SearchRepositoryKey.self] = newValue }
    }
}
