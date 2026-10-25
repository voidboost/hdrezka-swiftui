import Foundation

struct MovieSubtitles: Identifiable, Codable, Hashable {
    let name: String
    let link: String
    let lang: String
    var id = UUID()
}
