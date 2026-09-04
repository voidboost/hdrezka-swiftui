import Combine
import Dependencies

struct ReorderBookmarksCategoriesUseCase {
    @Dependency(\.accountRepository) private var repository

    func callAsFunction(newOrder: [Bookmark]) -> AnyPublisher<Bool, Error> {
        repository.reorderBookmarksCategories(newOrder: newOrder)
    }
}

extension ReorderBookmarksCategoriesUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var reorderBookmarksCategoriesUseCase: ReorderBookmarksCategoriesUseCase {
        get { self[ReorderBookmarksCategoriesUseCase.self] }
        set { self[ReorderBookmarksCategoriesUseCase.self] = newValue }
    }
}
