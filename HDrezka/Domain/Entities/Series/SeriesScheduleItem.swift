import Foundation

struct SeriesScheduleItem: Identifiable, Codable, Hashable {
    let title: String
    let russianEpisodeName: String
    let originalEpisodeName: String?
    let releaseDate: String
    var id = UUID()
}
