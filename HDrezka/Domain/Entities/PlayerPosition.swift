import Foundation
import SQLiteData

@Table("player_positions")
struct PlayerPosition: Identifiable, Hashable {
    @Selection
    struct ID: Hashable {
        let id: String

        let acting: String

        let season: String

        let episode: String

        init(id: String, acting: String, season: String? = nil, episode: String? = nil) {
            self.id = id
            self.acting = acting
            self.season = season ?? ""
            self.episode = episode ?? ""
        }
    }

    @Column(primaryKey: true)
    let id: ID

    let position: Double
}
