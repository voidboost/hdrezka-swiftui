import Foundation

struct MovieSeason: Identifiable, Hashable, Codable {
    let seasonId: String
    let name: String
    let episodes: [MovieEpisode]
    let isSelected: Bool
    let url: String?
    var id = UUID()
}
