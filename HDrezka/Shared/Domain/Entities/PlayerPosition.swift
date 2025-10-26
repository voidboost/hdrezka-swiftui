import Foundation
import SwiftData

@Model
class PlayerPosition {
    var id: String
    var acting: String
    var season: String?
    var episode: String?
    var position: Double

    init(id: String, acting: String, season: String? = nil, episode: String? = nil, position: Double) {
        self.id = id
        self.acting = acting
        self.season = season
        self.episode = episode
        self.position = position
    }
}
