import Foundation

struct MovieVoiceActingRating: Identifiable, Codable, Hashable {
    let name: String
    let percent: Float
    let id: UUID

    init(name: String, percent: Float, id: UUID = .init()) {
        self.name = name
        self.percent = percent
        self.id = id
    }
}
