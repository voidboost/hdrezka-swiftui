import Combine
import Dependencies

struct GetWatchingLaterMoviesUseCase {
    @Dependency(\.accountRepository) private var repository

    func callAsFunction() -> AnyPublisher<[MovieWatchLater], Error> {
        repository.getWatchingLaterMovies()
    }
}

extension GetWatchingLaterMoviesUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var getWatchingLaterMoviesUseCase: GetWatchingLaterMoviesUseCase {
        get { self[GetWatchingLaterMoviesUseCase.self] }
        set { self[GetWatchingLaterMoviesUseCase.self] = newValue }
    }
}
