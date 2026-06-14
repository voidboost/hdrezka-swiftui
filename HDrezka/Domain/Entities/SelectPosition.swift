import Foundation
import SwiftData

@Model
class SelectPosition {
    var id: String
    var acting: String
    var season: String?
    var episode: String?
    var subtitles: String?

    init(id: String, acting: String, season: String? = nil, episode: String? = nil, subtitles: String? = nil) {
        self.id = id
        self.acting = acting
        self.season = season
        self.episode = episode
        self.subtitles = subtitles
    }
}
