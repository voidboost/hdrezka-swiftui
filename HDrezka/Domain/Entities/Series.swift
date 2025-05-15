import Foundation

struct Series: Codable, Hashable {
    let acting: String
    let season: String
    let episode: String

    init(acting: String, season: String, episode: String) {
        self.acting = acting
        self.season = season
        self.episode = episode
    }
}
