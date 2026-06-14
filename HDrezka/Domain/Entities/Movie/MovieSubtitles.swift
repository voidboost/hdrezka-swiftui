import Foundation

struct MovieSubtitles: Identifiable, Codable, Hashable {
    let name: String
    let link: String
    let lang: String
    let id: UUID

    init(name: String, link: String, lang: String, id: UUID = .init()) {
        self.name = name
        self.link = link
        self.lang = lang
        self.id = id
    }
}
