import Combine
import Dependencies

struct GetPopularMoviesByGenreUseCase {
    @Dependency(\.movieListsRepository) private var repository

    func callAsFunction(genreId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        repository.getPopularMoviesByGenre(genreId: genreId, page: page)
    }
}

extension GetPopularMoviesByGenreUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var getPopularMoviesByGenreUseCase: GetPopularMoviesByGenreUseCase {
        get { self[GetPopularMoviesByGenreUseCase.self] }
        set { self[GetPopularMoviesByGenreUseCase.self] = newValue }
    }
}
