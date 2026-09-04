import Combine
import Dependencies

struct GetHotMoviesUseCase {
    @Dependency(\.movieListsRepository) private var repository

    func callAsFunction(genre: Int) -> AnyPublisher<[MovieSimple], Error> {
        repository.getHotMovies(genre: genre)
    }
}

extension GetHotMoviesUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var getHotMoviesUseCase: GetHotMoviesUseCase {
        get { self[GetHotMoviesUseCase.self] }
        set { self[GetHotMoviesUseCase.self] = newValue }
    }
}
