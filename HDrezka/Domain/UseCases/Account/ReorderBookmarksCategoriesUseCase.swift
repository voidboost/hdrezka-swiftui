import Combine

struct ReorderBookmarksCategoriesUseCase {
    private let repository: AccountRepository

    init(repository: AccountRepository) {
        self.repository = repository
    }

    func callAsFunction(newOrder: [Bookmark]) -> AnyPublisher<Bool, Error> {
        repository.reorderBookmarksCategories(newOrder: newOrder)
    }
}
