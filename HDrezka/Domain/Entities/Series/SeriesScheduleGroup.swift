import Foundation

struct SeriesScheduleGroup: Identifiable, Codable, Hashable {
    let name: String
    let items: [SeriesScheduleItem]
    let id: UUID

    init(name: String, items: [SeriesScheduleItem], id: UUID = .init()) {
        self.name = name
        self.items = items
        self.id = id
    }
}
