import Combine
import Dependencies

struct GetBookmarksByCategoryYearUseCase {
    @Dependency(\.accountRepository) private var repository

    func callAsFunction(id: Int, genre: Int, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        repository.getBookmarksByCategoryYear(id: id, genre: genre, page: page)
    }
}

extension GetBookmarksByCategoryYearUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var getBookmarksByCategoryYearUseCase: GetBookmarksByCategoryYearUseCase {
        get { self[GetBookmarksByCategoryYearUseCase.self] }
        set { self[GetBookmarksByCategoryYearUseCase.self] = newValue }
    }
}
