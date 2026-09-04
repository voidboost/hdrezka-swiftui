import Combine
import Dependencies

struct ChangeBookmarksCategoryNameUseCase {
    @Dependency(\.accountRepository) private var repository

    func callAsFunction(id: Int, newName: String) -> AnyPublisher<Bool, Error> {
        repository.changeBookmarksCategoryName(id: id, newName: newName)
    }
}

extension ChangeBookmarksCategoryNameUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var changeBookmarksCategoryNameUseCase: ChangeBookmarksCategoryNameUseCase {
        get { self[ChangeBookmarksCategoryNameUseCase.self] }
        set { self[ChangeBookmarksCategoryNameUseCase.self] = newValue }
    }
}
