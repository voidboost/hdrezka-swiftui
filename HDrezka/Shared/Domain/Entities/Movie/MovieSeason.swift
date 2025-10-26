import Foundation

struct MovieSeason: Identifiable, Hashable, Codable {
    let seasonId: String
    let name: String
    let episodes: [MovieEpisode]
    let isSelected: Bool
    let url: String?
    let id: UUID

    init(seasonId: String, name: String, episodes: [MovieEpisode], isSelected: Bool, url: String?, id: UUID = .init()) {
        self.seasonId = seasonId
        self.name = name
        self.episodes = episodes
        self.isSelected = isSelected
        self.url = url
        self.id = id
    }
}
