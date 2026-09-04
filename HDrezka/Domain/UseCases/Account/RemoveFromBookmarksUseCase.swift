import Combine
import Dependencies

struct RemoveFromBookmarksUseCase {
    @Dependency(\.accountRepository) private var repository

    func callAsFunction(movies: [String], bookmarkUserCategory: Int) -> AnyPublisher<Bool, Error> {
        repository.removeFromBookmarks(movies: movies, bookmarkUserCategory: bookmarkUserCategory)
    }
}

extension RemoveFromBookmarksUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var removeFromBookmarksUseCase: RemoveFromBookmarksUseCase {
        get { self[RemoveFromBookmarksUseCase.self] }
        set { self[RemoveFromBookmarksUseCase.self] = newValue }
    }
}
