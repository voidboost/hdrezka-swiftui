import Combine

struct RemoveWatchingItemUseCase {
    private let repository: AccountRepository

    init(repository: AccountRepository) {
        self.repository = repository
    }

    func callAsFunction(item: MovieWatchLater) -> AnyPublisher<Bool, Error> {
        repository.removeWatchingItem(item: item)
    }
}
