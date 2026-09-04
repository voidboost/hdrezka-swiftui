import Combine
import Dependencies

struct DeleteBookmarksCategoryUseCase {
    @Dependency(\.accountRepository) private var repository

    func callAsFunction(id: Int) -> AnyPublisher<Bool, Error> {
        repository.deleteBookmarksCategory(id: id)
    }
}

extension DeleteBookmarksCategoryUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var deleteBookmarksCategoryUseCase: DeleteBookmarksCategoryUseCase {
        get { self[DeleteBookmarksCategoryUseCase.self] }
        set { self[DeleteBookmarksCategoryUseCase.self] = newValue }
    }
}
