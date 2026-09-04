import Combine
import Dependencies

struct GetPopularNewestMoviesUseCase {
    @Dependency(\.movieListsRepository) private var repository

    func callAsFunction(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error> {
        repository.getPopularNewestMovies(page: page, genre: genre)
    }
}

extension GetPopularNewestMoviesUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var getPopularNewestMoviesUseCase: GetPopularNewestMoviesUseCase {
        get { self[GetPopularNewestMoviesUseCase.self] }
        set { self[GetPopularNewestMoviesUseCase.self] = newValue }
    }
}
