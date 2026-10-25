import Foundation

struct MovieVoiceActingRating: Identifiable, Codable, Hashable {
    let name: String
    let percent: Float
    var id = UUID()
}
