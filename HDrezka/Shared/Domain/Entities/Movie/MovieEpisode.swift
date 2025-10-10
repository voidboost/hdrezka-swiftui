import Foundation

struct MovieEpisode: Identifiable, Hashable, Codable {
    let episodeId: String
    let name: String
    let isSelected: Bool
    let url: String?
    let id: UUID

    init(episodeId: String, name: String, isSelected: Bool, url: String?, id: UUID = .init()) {
        self.episodeId = episodeId
        self.name = name
        self.isSelected = isSelected
        self.url = url
        self.id = id
    }
}
