import Combine
import Dependencies

struct GetMovieThumbnailsUseCase {
    @Dependency(\.movieDetailsRepository) private var repository

    func callAsFunction(path: String) -> AnyPublisher<WebVTT, Error> {
        repository.getMovieThumbnails(path: path)
    }
}

extension GetMovieThumbnailsUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var getMovieThumbnailsUseCase: GetMovieThumbnailsUseCase {
        get { self[GetMovieThumbnailsUseCase.self] }
        set { self[GetMovieThumbnailsUseCase.self] = newValue }
    }
}
