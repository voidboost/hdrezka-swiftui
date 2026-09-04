import Combine
import Dependencies

struct RemoveWatchingItemUseCase {
    @Dependency(\.accountRepository) private var repository

    func callAsFunction(item: MovieWatchLater) -> AnyPublisher<Bool, Error> {
        repository.removeWatchingItem(item: item)
    }
}

extension RemoveWatchingItemUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var removeWatchingItemUseCase: RemoveWatchingItemUseCase {
        get { self[RemoveWatchingItemUseCase.self] }
        set { self[RemoveWatchingItemUseCase.self] = newValue }
    }
}
