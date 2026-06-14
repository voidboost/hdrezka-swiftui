import Combine

protocol SearchRepository {
    func search(query: String, page: Int) -> AnyPublisher<[MovieSimple], Error>

    func categories() -> AnyPublisher<[MovieType], Error>
}
