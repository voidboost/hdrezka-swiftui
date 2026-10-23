import Dependencies

struct GetMovieVideoUseCase {
    @Dependency(\.movieDetailsRepository) private var repository

    func callAsFunction(voiceActing: MovieVoiceActing, season: MovieSeason?, episode: MovieEpisode?, favs: String) async throws -> MovieVideo {
        try await repository.getMovieVideo(voiceActing: voiceActing, season: season, episode: episode, favs: favs)
    }
}

extension GetMovieVideoUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var getMovieVideoUseCase: GetMovieVideoUseCase {
        get { self[GetMovieVideoUseCase.self] }
        set { self[GetMovieVideoUseCase.self] = newValue }
    }
}
