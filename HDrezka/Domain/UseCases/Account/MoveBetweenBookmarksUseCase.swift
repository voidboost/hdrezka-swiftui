import Combine
import Dependencies

struct MoveBetweenBookmarksUseCase {
    @Dependency(\.accountRepository) private var repository

    func callAsFunction(movies: [String], fromBookmarkUserCategory: Int, toBookmarkUserCategory: Int) -> AnyPublisher<Int, Error> {
        repository.moveBetweenBookmarks(movies: movies, fromBookmarkUserCategory: fromBookmarkUserCategory, toBookmarkUserCategory: toBookmarkUserCategory)
    }
}

extension MoveBetweenBookmarksUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var moveBetweenBookmarksUseCase: MoveBetweenBookmarksUseCase {
        get { self[MoveBetweenBookmarksUseCase.self] }
        set { self[MoveBetweenBookmarksUseCase.self] = newValue }
    }
}
