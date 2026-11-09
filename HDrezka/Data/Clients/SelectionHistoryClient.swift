import Defaults
import Dependencies
import DependenciesMacros
import SQLiteData

@DependencyClient
struct SelectionHistoryClient {
    var remember: @Sendable (_ acting: MovieVoiceActing, _ season: MovieSeason?, _ episode: MovieEpisode?, _ subtitles: String?) async -> Void
    var save: @Sendable (_ acting: MovieVoiceActing, _ season: MovieSeason?, _ episode: MovieEpisode?, _ subtitles: String?) async -> Void
}

extension SelectionHistoryClient: DependencyKey {
    static let liveValue: Self = {
        @Dependency(\.defaultDatabase) var database
        @Dependency(\.accountClient) var accountClient

        let save: @Sendable (MovieVoiceActing, MovieSeason?, MovieEpisode?, String?) async -> Void = { acting, season, episode, subtitles in
            try? await database.write { db in
                try SelectPosition
                    .upsert {
                        SelectPosition.Draft(
                            id: acting.voiceId,
                            acting: acting.translatorId,
                            season: season?.seasonId,
                            episode: episode?.episodeId,
                            subtitles: subtitles,
                        )
                    }
                    .execute(db)
            }
        }

        return Self(
            remember: { acting, season, episode, subtitles in
                if Defaults[.isLoggedIn] {
                    try? await accountClient.saveWatchingState(voiceActing: acting, season: season, episode: episode)
                }

                await save(acting, season, episode, subtitles)
            },
            save: save,
        )
    }()
}

extension DependencyValues {
    var selectionHistory: SelectionHistoryClient {
        get { self[SelectionHistoryClient.self] }
        set { self[SelectionHistoryClient.self] = newValue }
    }
}
