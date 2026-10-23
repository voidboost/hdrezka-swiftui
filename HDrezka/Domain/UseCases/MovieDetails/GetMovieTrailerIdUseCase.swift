import Dependencies

struct GetMovieTrailerIdUseCase {
    @Dependency(\.movieDetailsRepository) private var repository

    func callAsFunction(movieId: String) async throws -> String {
        try await repository.getMovieTrailerId(movieId: movieId)
    }
}

extension GetMovieTrailerIdUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var getMovieTrailerIdUseCase: GetMovieTrailerIdUseCase {
        get { self[GetMovieTrailerIdUseCase.self] }
        set { self[GetMovieTrailerIdUseCase.self] = newValue }
    }
}
