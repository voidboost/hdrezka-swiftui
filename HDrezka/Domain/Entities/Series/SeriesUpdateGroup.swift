import Foundation

struct SeriesUpdateGroup: Identifiable, Hashable {
    let date: String
    let releasedEpisodes: [SeriesUpdateItem]
    var id = UUID()
}
