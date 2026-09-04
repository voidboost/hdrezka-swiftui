import Combine
import Dependencies

struct GetMovieDetailsUseCase {
    @Dependency(\.movieDetailsRepository) private var repository

    func callAsFunction(movieId: String) -> AnyPublisher<MovieDetailed, Error> {
        repository.getMovieDetails(movieId: movieId)
    }
}

extension GetMovieDetailsUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var getMovieDetailsUseCase: GetMovieDetailsUseCase {
        get { self[GetMovieDetailsUseCase.self] }
        set { self[GetMovieDetailsUseCase.self] = newValue }
    }
}
