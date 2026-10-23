import Dependencies

struct GetSeriesUpdatesUseCase {
    @Dependency(\.accountRepository) private var repository

    func callAsFunction() async throws -> [SeriesUpdateGroup] {
        try await repository.getSeriesUpdates()
    }
}

extension GetSeriesUpdatesUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var getSeriesUpdatesUseCase: GetSeriesUpdatesUseCase {
        get { self[GetSeriesUpdatesUseCase.self] }
        set { self[GetSeriesUpdatesUseCase.self] = newValue }
    }
}
