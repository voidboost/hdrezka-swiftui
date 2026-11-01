import Foundation
import SQLiteData

@Table("select_positions")
struct SelectPosition: Identifiable, Hashable {
    @Column(primaryKey: true)
    let id: String

    let acting: String

    var season: String?

    var episode: String?

    var subtitles: String?
}
