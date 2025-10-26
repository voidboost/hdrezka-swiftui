import Combine

struct GetSeriesUpdatesUseCase {
    private let repository: AccountRepository

    init(repository: AccountRepository) {
        self.repository = repository
    }

    func callAsFunction() -> AnyPublisher<[SeriesUpdateGroup], Error> {
        repository.getSeriesUpdates()
    }
}
