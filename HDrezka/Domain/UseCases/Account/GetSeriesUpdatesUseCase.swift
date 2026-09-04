import Combine
import Dependencies

struct GetSeriesUpdatesUseCase {
    @Dependency(\.accountRepository) private var repository

    func callAsFunction() -> AnyPublisher<[SeriesUpdateGroup], Error> {
        repository.getSeriesUpdates()
    }
}

extension GetSeriesUpdatesUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var getSeriesUpdatesUseCase: GetSeriesUpdatesUseCase {
        get { self[GetSeriesUpdatesUseCase.self] }
        set { self[GetSeriesUpdatesUseCase.self] = newValue }
    }
}
