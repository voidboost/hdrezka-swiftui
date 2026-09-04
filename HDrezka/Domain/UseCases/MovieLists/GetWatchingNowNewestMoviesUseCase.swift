import Combine
import Dependencies

struct GetWatchingNowNewestMoviesUseCase {
    @Dependency(\.movieListsRepository) private var repository

    func callAsFunction(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error> {
        repository.getWatchingNowNewestMovies(page: page, genre: genre)
    }
}

extension GetWatchingNowNewestMoviesUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var getWatchingNowNewestMoviesUseCase: GetWatchingNowNewestMoviesUseCase {
        get { self[GetWatchingNowNewestMoviesUseCase.self] }
        set { self[GetWatchingNowNewestMoviesUseCase.self] = newValue }
    }
}
