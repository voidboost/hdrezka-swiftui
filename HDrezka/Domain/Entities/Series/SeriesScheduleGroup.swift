import Foundation

struct SeriesScheduleGroup: Identifiable, Codable, Hashable {
    let name: String
    let items: [SeriesScheduleItem]
    var id = UUID()
}
