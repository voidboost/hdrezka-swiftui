import Combine
import Dependencies

struct GetLatestNewestMoviesUseCase {
    @Dependency(\.movieListsRepository) private var repository

    func callAsFunction(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error> {
        repository.getLatestNewestMovies(page: page, genre: genre)
    }
}

extension GetLatestNewestMoviesUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var getLatestNewestMoviesUseCase: GetLatestNewestMoviesUseCase {
        get { self[GetLatestNewestMoviesUseCase.self] }
        set { self[GetLatestNewestMoviesUseCase.self] = newValue }
    }
}
