import Dependencies

struct SwitchWatchedItemUseCase {
    @Dependency(\.accountRepository) private var repository

    func callAsFunction(item: MovieWatchLater) async throws {
        try await repository.switchWatchedItem(item: item)
    }
}

extension SwitchWatchedItemUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var switchWatchedItemUseCase: SwitchWatchedItemUseCase {
        get { self[SwitchWatchedItemUseCase.self] }
        set { self[SwitchWatchedItemUseCase.self] = newValue }
    }
}
