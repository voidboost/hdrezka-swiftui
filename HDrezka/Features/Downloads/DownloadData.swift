import Foundation

struct DownloadData: Identifiable, Codable, Hashable {
    let details: MovieDetailed
    let acting: MovieVoiceActing
    let season: MovieSeason?
    private(set) var episode: MovieEpisode?
    let quality: String
    let subtitles: MovieSubtitles?
    let all: Bool
    private(set) var folder: Data?
    let id: UUID

    init(details: MovieDetailed, acting: MovieVoiceActing, season: MovieSeason? = nil, episode: MovieEpisode? = nil, quality: String, subtitles: MovieSubtitles? = nil, all: Bool = false, id: UUID = .init()) {
        self.details = details
        self.acting = acting
        self.season = season
        self.episode = episode
        self.quality = quality
        self.subtitles = subtitles
        self.all = all
        folder = nil
        self.id = id
    }
}

extension DownloadData {
    func withEpisode(_ episode: MovieEpisode) -> DownloadData {
        var data = self
        data.episode = episode

        return data
    }

    func withFolder(_ folder: Data) -> DownloadData {
        var data = self
        data.folder = folder

        return data
    }

    func isSameSeason(as other: DownloadData) -> Bool {
        details.movieId == other.details.movieId
            && season?.seasonId == other.season?.seasonId
            && acting.translatorId == other.acting.translatorId
            && quality == other.quality
    }

    var notificationId: String {
        if let season, let episode {
            "\(details.movieId)\(season.seasonId)\(episode.episodeId)\(acting.translatorId)\(quality)".base64Encoded
        } else {
            "\(details.movieId)\(acting.translatorId)\(quality)".base64Encoded
        }
    }

    var name: String {
        if let seasonName, let episodeName {
            "\(details.nameRussian) \(seasonName) \(episodeName)\(suffix)"
        } else {
            "\(details.nameRussian)\(suffix)"
        }
    }

    var suffix: String {
        let qualityName = quality.isEmpty ? "" : " [\(quality)]"
        let actingName = acting.name.isEmpty ? "" : " [\(acting.name)]"

        return "\(qualityName)\(actingName)"
    }

    var seasonName: String? {
        season.map { String(localized: "key.season-\($0.name.contains(/^\d/) ? $0.name : $0.seasonId)") }
    }

    var episodeName: String? {
        episode.map { String(localized: "key.episode-\($0.name.contains(/^\d/) ? $0.name : $0.episodeId)") }
    }

    var retryData: Data? {
        try? JSONEncoder().encode(self)
    }
}
