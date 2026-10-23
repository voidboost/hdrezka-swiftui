import Dependencies

struct GetMovieThumbnailsUseCase {
    @Dependency(\.movieDetailsRepository) private var repository

    func callAsFunction(path: String) async throws -> WebVTT {
        try await repository.getMovieThumbnails(path: path)
    }
}

extension GetMovieThumbnailsUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var getMovieThumbnailsUseCase: GetMovieThumbnailsUseCase {
        get { self[GetMovieThumbnailsUseCase.self] }
        set { self[GetMovieThumbnailsUseCase.self] = newValue }
    }
}
