import Combine
import Dependencies

struct GetBookmarksUseCase {
    @Dependency(\.accountRepository) private var repository

    func callAsFunction() -> AnyPublisher<[Bookmark], Error> {
        repository.getBookmarks()
    }
}

extension GetBookmarksUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var getBookmarksUseCase: GetBookmarksUseCase {
        get { self[GetBookmarksUseCase.self] }
        set { self[GetBookmarksUseCase.self] = newValue }
    }
}
