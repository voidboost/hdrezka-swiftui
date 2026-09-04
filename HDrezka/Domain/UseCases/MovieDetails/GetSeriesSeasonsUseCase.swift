import Combine
import Dependencies

struct GetSeriesSeasonsUseCase {
    @Dependency(\.movieDetailsRepository) private var repository

    func callAsFunction(movieId: String, voiceActing: MovieVoiceActing, favs: String) -> AnyPublisher<[MovieSeason], Error> {
        repository.getSeriesSeasons(movieId: movieId, voiceActing: voiceActing, favs: favs)
    }
}

extension GetSeriesSeasonsUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var getSeriesSeasonsUseCase: GetSeriesSeasonsUseCase {
        get { self[GetSeriesSeasonsUseCase.self] }
        set { self[GetSeriesSeasonsUseCase.self] = newValue }
    }
}
