import Combine
import Dependencies

struct SearchUseCase {
    @Dependency(\.searchRepository) private var repository

    func callAsFunction(query: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        repository.search(query: query, page: page)
    }
}

extension SearchUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var searchUseCase: SearchUseCase {
        get { self[SearchUseCase.self] }
        set { self[SearchUseCase.self] = newValue }
    }
}
