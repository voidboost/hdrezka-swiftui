import Combine
import Dependencies

struct GetMovieTrailerIdUseCase {
    @Dependency(\.movieDetailsRepository) private var repository

    func callAsFunction(movieId: String) -> AnyPublisher<String, Error> {
        repository.getMovieTrailerId(movieId: movieId)
    }
}

extension GetMovieTrailerIdUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var getMovieTrailerIdUseCase: GetMovieTrailerIdUseCase {
        get { self[GetMovieTrailerIdUseCase.self] }
        set { self[GetMovieTrailerIdUseCase.self] = newValue }
    }
}
