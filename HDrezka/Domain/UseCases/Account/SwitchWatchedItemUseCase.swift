import Combine

struct SwitchWatchedItemUseCase {
    private let repository: AccountRepository

    init(repository: AccountRepository) {
        self.repository = repository
    }

    func callAsFunction(item: MovieWatchLater) -> AnyPublisher<Bool, Error> {
        repository.switchWatchedItem(item: item)
    }
}
