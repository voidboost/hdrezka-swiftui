import Foundation

struct SeriesScheduleItem: Identifiable, Codable, Hashable {
    let title: String
    let russianEpisodeName: String
    let originalEpisodeName: String?
    let releaseDate: String
    let id: UUID

    init(title: String, russianEpisodeName: String, originalEpisodeName: String?, releaseDate: String, id: UUID = .init()) {
        self.title = title
        self.russianEpisodeName = russianEpisodeName
        self.originalEpisodeName = originalEpisodeName
        self.releaseDate = releaseDate
        self.id = id
    }
}
