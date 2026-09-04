import Combine
import Dependencies

struct GetPopularMoviesUseCase {
    @Dependency(\.movieListsRepository) private var repository

    func callAsFunction(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error> {
        repository.getPopularMovies(page: page, genre: genre)
    }
}

extension GetPopularMoviesUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var getPopularMoviesUseCase: GetPopularMoviesUseCase {
        get { self[GetPopularMoviesUseCase.self] }
        set { self[GetPopularMoviesUseCase.self] = newValue }
    }
}
