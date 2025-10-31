import Combine

struct SaveWatchingStateUseCase {
    private let repository: AccountRepository

    init(repository: AccountRepository) {
        self.repository = repository
    }

    func callAsFunction(voiceActing: MovieVoiceActing, season: MovieSeason?, episode: MovieEpisode?, position: Int? = nil, total: Int? = nil) -> AnyPublisher<Bool, Error> {
        repository.saveWatchingState(voiceActing: voiceActing, season: season, episode: episode, position: position, total: total)
    }
}
