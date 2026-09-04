import Combine
import Dependencies

struct GetLatestMoviesUseCase {
    @Dependency(\.movieListsRepository) private var repository

    func callAsFunction(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error> {
        repository.getLatestMovies(page: page, genre: genre)
    }
}

extension GetLatestMoviesUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var getLatestMoviesUseCase: GetLatestMoviesUseCase {
        get { self[GetLatestMoviesUseCase.self] }
        set { self[GetLatestMoviesUseCase.self] = newValue }
    }
}
