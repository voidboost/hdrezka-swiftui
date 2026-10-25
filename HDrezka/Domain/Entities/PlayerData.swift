import Foundation

struct PlayerData: Identifiable, Codable, Hashable {
    let details: MovieDetailed
    let selectedActing: MovieVoiceActing
    let seasons: [MovieSeason]?
    let selectedSeason: MovieSeason?
    let selectedEpisode: MovieEpisode?
    let selectedQuality: String
    let movie: MovieVideo
    var id = UUID()
}
