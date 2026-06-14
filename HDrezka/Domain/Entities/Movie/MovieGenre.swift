import Foundation

struct MovieGenre: Codable, Named {
    let name: String
    let genreId: String
    let id: UUID

    init(name: String, genreId: String, id: UUID = .init()) {
        self.name = name
        self.genreId = genreId
        self.id = id
    }
}
