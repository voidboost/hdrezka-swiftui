import Combine

struct SaveWatchingStateUseCase {
    private let repository: AccountRepository

    init(repository: AccountRepository) {
        self.repository = repository
    }

    func callAsFunction(voiceActing: MovieVoiceActing, season: MovieSeason?, episode: MovieEpisode?, position: Int, total: Int) -> AnyPublisher<Bool, Error> {
        repository.saveWatchingState(voiceActing: voiceActing, season: season, episode: episode, position: position, total: total)
    }
}
