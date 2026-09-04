import Combine
import Dependencies

struct GetSoonMoviesByGenreUseCase {
    @Dependency(\.movieListsRepository) private var repository

    func callAsFunction(genreId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        repository.getSoonMoviesByGenre(genreId: genreId, page: page)
    }
}

extension GetSoonMoviesByGenreUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var getSoonMoviesByGenreUseCase: GetSoonMoviesByGenreUseCase {
        get { self[GetSoonMoviesByGenreUseCase.self] }
        set { self[GetSoonMoviesByGenreUseCase.self] = newValue }
    }
}
