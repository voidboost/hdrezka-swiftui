import Combine

struct ChangeBookmarksCategoryNameUseCase {
    private let repository: AccountRepository

    init(repository: AccountRepository) {
        self.repository = repository
    }

    func callAsFunction(id: Int, newName: String) -> AnyPublisher<Bool, Error> {
        repository.changeBookmarksCategoryName(id: id, newName: newName)
    }
}
