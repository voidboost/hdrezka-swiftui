import Combine
import Dependencies

struct AddToBookmarksUseCase {
    @Dependency(\.accountRepository) private var repository

    func callAsFunction(movieId: String, bookmarkUserCategory: Int) -> AnyPublisher<Bool, Error> {
        repository.addToBookmarks(movieId: movieId, bookmarkUserCategory: bookmarkUserCategory)
    }
}

extension AddToBookmarksUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var addToBookmarksUseCase: AddToBookmarksUseCase {
        get { self[AddToBookmarksUseCase.self] }
        set { self[AddToBookmarksUseCase.self] = newValue }
    }
}
