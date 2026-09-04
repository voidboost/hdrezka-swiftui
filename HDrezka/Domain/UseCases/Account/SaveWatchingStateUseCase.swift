import Combine
import Dependencies

struct SaveWatchingStateUseCase {
    @Dependency(\.accountRepository) private var repository

    func callAsFunction(voiceActing: MovieVoiceActing, season: MovieSeason?, episode: MovieEpisode?, position: Int? = nil, total: Int? = nil) -> AnyPublisher<Bool, Error> {
        repository.saveWatchingState(voiceActing: voiceActing, season: season, episode: episode, position: position, total: total)
    }
}

extension SaveWatchingStateUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var saveWatchingStateUseCase: SaveWatchingStateUseCase {
        get { self[SaveWatchingStateUseCase.self] }
        set { self[SaveWatchingStateUseCase.self] = newValue }
    }
}
