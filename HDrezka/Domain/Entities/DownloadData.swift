import Foundation

struct DownloadData: Identifiable, Codable, Hashable {
    let details: MovieDetailed
    let acting: MovieVoiceActing
    let season: MovieSeason?
    private(set) var episode: MovieEpisode?
    let quality: String
    let subtitles: MovieSubtitles?
    let all: Bool
    let id: UUID

    init(details: MovieDetailed, acting: MovieVoiceActing, season: MovieSeason? = nil, episode: MovieEpisode? = nil, quality: String, subtitles: MovieSubtitles? = nil, all: Bool = false, id: UUID = .init()) {
        self.details = details
        self.acting = acting
        self.season = season
        self.episode = episode
        self.quality = quality
        self.subtitles = subtitles
        self.all = all
        self.id = id
    }
}

extension DownloadData {
    func newEpisede(_ episode: MovieEpisode) -> DownloadData {
        var data = self
        data.episode = episode

        return data
    }

    var notificationId: String {
        if let season, let episode {
            "\(details.movieId)\(season.seasonId)\(episode.episodeId)\(acting.translatorId)\(quality)".base64Encoded
        } else {
            "\(details.movieId)\(acting.translatorId)\(quality)".base64Encoded
        }
    }

    var name: String {
        let name = details.nameRussian

        let actingName = if !acting.name.isEmpty {
            " [\(acting.name)]"
        } else {
            ""
        }

        let qualityName = if !quality.isEmpty {
            " [\(quality)]"
        } else {
            ""
        }

        if let season, let episode {
            let (seasonName, episodeName) = (
                String(localized: "key.season-\(season.name.contains(/^\d/) ? season.name : season.seasonId)"),
                String(localized: "key.episode-\(episode.name.contains(/^\d/) ? episode.name : episode.episodeId)"),
            )

            return "\(name) \(seasonName) \(episodeName)\(qualityName)\(actingName)"
        } else {
            return "\(name)\(qualityName)\(actingName)"
        }
    }

    var retryData: Data? {
        try? JSONEncoder().encode(self)
    }
}
