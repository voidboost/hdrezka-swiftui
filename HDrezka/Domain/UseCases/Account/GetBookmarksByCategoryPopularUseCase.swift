import Combine
import Dependencies

struct GetBookmarksByCategoryPopularUseCase {
    @Dependency(\.accountRepository) private var repository

    func callAsFunction(id: Int, genre: Int, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        repository.getBookmarksByCategoryPopular(id: id, genre: genre, page: page)
    }
}

extension GetBookmarksByCategoryPopularUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var getBookmarksByCategoryPopularUseCase: GetBookmarksByCategoryPopularUseCase {
        get { self[GetBookmarksByCategoryPopularUseCase.self] }
        set { self[GetBookmarksByCategoryPopularUseCase.self] = newValue }
    }
}
