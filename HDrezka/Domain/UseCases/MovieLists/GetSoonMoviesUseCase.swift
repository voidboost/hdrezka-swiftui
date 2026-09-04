import Combine
import Dependencies

struct GetSoonMoviesUseCase {
    @Dependency(\.movieListsRepository) private var repository

    func callAsFunction(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error> {
        repository.getSoonMovies(page: page, genre: genre)
    }
}

extension GetSoonMoviesUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var getSoonMoviesUseCase: GetSoonMoviesUseCase {
        get { self[GetSoonMoviesUseCase.self] }
        set { self[GetSoonMoviesUseCase.self] = newValue }
    }
}
