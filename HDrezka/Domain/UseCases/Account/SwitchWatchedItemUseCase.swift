import Combine
import Dependencies

struct SwitchWatchedItemUseCase {
    @Dependency(\.accountRepository) private var repository

    func callAsFunction(item: MovieWatchLater) -> AnyPublisher<Bool, Error> {
        repository.switchWatchedItem(item: item)
    }
}

extension SwitchWatchedItemUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var switchWatchedItemUseCase: SwitchWatchedItemUseCase {
        get { self[SwitchWatchedItemUseCase.self] }
        set { self[SwitchWatchedItemUseCase.self] = newValue }
    }
}
