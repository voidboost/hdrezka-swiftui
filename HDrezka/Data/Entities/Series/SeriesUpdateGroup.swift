import Foundation

struct SeriesUpdateGroup: Identifiable, Hashable {
    let date: String
    let releasedEpisodes: [SeriesUpdateItem]
    let id: UUID

    init(date: String, releasedEpisodes: [SeriesUpdateItem], id: UUID = .init()) {
        self.date = date
        self.releasedEpisodes = releasedEpisodes
        self.id = id
    }
}
