import Combine
import Dependencies

struct CreateBookmarksCategoryUseCase {
    @Dependency(\.accountRepository) private var repository

    func callAsFunction(name: String) -> AnyPublisher<Bookmark, Error> {
        repository.createBookmarksCategory(name: name)
    }
}

extension CreateBookmarksCategoryUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var createBookmarksCategoryUseCase: CreateBookmarksCategoryUseCase {
        get { self[CreateBookmarksCategoryUseCase.self] }
        set { self[CreateBookmarksCategoryUseCase.self] = newValue }
    }
}
