import Combine
import Dependencies

struct GetBookmarksByCategoryAddedUseCase {
    @Dependency(\.accountRepository) private var repository

    func callAsFunction(id: Int, genre: Int, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        repository.getBookmarksByCategoryAdded(id: id, genre: genre, page: page)
    }
}

extension GetBookmarksByCategoryAddedUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var getBookmarksByCategoryAddedUseCase: GetBookmarksByCategoryAddedUseCase {
        get { self[GetBookmarksByCategoryAddedUseCase.self] }
        set { self[GetBookmarksByCategoryAddedUseCase.self] = newValue }
    }
}
