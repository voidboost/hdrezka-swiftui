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

    func newEpisede(_ episode: MovieEpisode) -> DownloadData {
        var data = self
        data.episode = episode

        return data
    }
}
