import Combine
import Dependencies

struct GetMovieBookmarksUseCase {
    @Dependency(\.movieDetailsRepository) private var repository

    func callAsFunction(movieId: String) -> AnyPublisher<[Bookmark], Error> {
        repository.getMovieBookmarks(movieId: movieId)
    }
}

extension GetMovieBookmarksUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var getMovieBookmarksUseCase: GetMovieBookmarksUseCase {
        get { self[GetMovieBookmarksUseCase.self] }
        set { self[GetMovieBookmarksUseCase.self] = newValue }
    }
}
