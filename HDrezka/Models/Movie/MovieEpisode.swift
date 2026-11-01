import Foundation

struct MovieEpisode: Identifiable, Hashable, Codable {
    let episodeId: String
    let name: String
    let isSelected: Bool
    let url: String?
    var id = UUID()
}
