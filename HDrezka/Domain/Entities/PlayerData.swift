import Foundation

struct PlayerData: Identifiable, Codable, Hashable {
    let details: MovieDetailed
    let selectedActing: MovieVoiceActing
    let seasons: [MovieSeason]?
    let selectedSeason: MovieSeason?
    let selectedEpisode: MovieEpisode?
    let selectedQuality: String
    let movie: MovieVideo
    let id: UUID

    init(details: MovieDetailed, selectedActing: MovieVoiceActing, seasons: [MovieSeason]?, selectedSeason: MovieSeason?, selectedEpisode: MovieEpisode?, selectedQuality: String, movie: MovieVideo, id: UUID = .init()) {
        self.details = details
        self.selectedActing = selectedActing
        self.seasons = seasons
        self.selectedSeason = selectedSeason
        self.selectedEpisode = selectedEpisode
        self.selectedQuality = selectedQuality
        self.movie = movie
        self.id = id
    }
}
