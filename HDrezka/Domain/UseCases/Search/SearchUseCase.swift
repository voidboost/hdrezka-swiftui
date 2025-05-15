import Combine

struct SearchUseCase {
    private let repository: SearchRepository

    init(repository: SearchRepository) {
        self.repository = repository
    }

    func callAsFunction(query: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        repository.search(query: query, page: page)
    }
}
