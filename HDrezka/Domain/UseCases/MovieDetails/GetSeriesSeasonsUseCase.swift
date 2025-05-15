import Combine

struct GetSeriesSeasonsUseCase {
    private let repository: MovieDetailsRepository

    init(repository: MovieDetailsRepository) {
        self.repository = repository
    }

    func callAsFunction(movieId: String, voiceActing: MovieVoiceActing, favs: String) -> AnyPublisher<[MovieSeason], Error> {
        repository.getSeriesSeasons(movieId: movieId, voiceActing: voiceActing, favs: favs)
    }
}
