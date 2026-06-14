import Combine

struct GetMovieVideoUseCase {
    private let repository: MovieDetailsRepository

    init(repository: MovieDetailsRepository) {
        self.repository = repository
    }

    func callAsFunction(voiceActing: MovieVoiceActing, season: MovieSeason?, episode: MovieEpisode?, favs: String) -> AnyPublisher<MovieVideo, Error> {
        repository.getMovieVideo(voiceActing: voiceActing, season: season, episode: episode, favs: favs)
    }
}
