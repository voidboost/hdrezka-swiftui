import Dependencies

struct RemoveWatchingItemUseCase {
    @Dependency(\.accountRepository) private var repository

    func callAsFunction(item: MovieWatchLater) async throws -> Bool {
        try await repository.removeWatchingItem(item: item)
    }
}

extension RemoveWatchingItemUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var removeWatchingItemUseCase: RemoveWatchingItemUseCase {
        get { self[RemoveWatchingItemUseCase.self] }
        set { self[RemoveWatchingItemUseCase.self] = newValue }
    }
}
