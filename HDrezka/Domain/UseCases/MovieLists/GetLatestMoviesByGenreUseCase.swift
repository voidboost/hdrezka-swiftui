import Combine
import Dependencies

struct GetLatestMoviesByGenreUseCase {
    @Dependency(\.movieListsRepository) private var repository

    func callAsFunction(genreId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        repository.getLatestMoviesByGenre(genreId: genreId, page: page)
    }
}

extension GetLatestMoviesByGenreUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var getLatestMoviesByGenreUseCase: GetLatestMoviesByGenreUseCase {
        get { self[GetLatestMoviesByGenreUseCase.self] }
        set { self[GetLatestMoviesByGenreUseCase.self] = newValue }
    }
}
