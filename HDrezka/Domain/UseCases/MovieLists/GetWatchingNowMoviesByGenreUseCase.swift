import Combine
import Dependencies

struct GetWatchingNowMoviesByGenreUseCase {
    @Dependency(\.movieListsRepository) private var repository

    func callAsFunction(genreId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        repository.getWatchingNowMoviesByGenre(genreId: genreId, page: page)
    }
}

extension GetWatchingNowMoviesByGenreUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var getWatchingNowMoviesByGenreUseCase: GetWatchingNowMoviesByGenreUseCase {
        get { self[GetWatchingNowMoviesByGenreUseCase.self] }
        set { self[GetWatchingNowMoviesByGenreUseCase.self] = newValue }
    }
}
