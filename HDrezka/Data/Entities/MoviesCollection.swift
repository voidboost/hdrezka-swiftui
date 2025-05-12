import Foundation

struct MoviesCollection: Codable, Named {
    let collectionId: String
    let name: String
    let poster: String?
    let count: Int?
    let id: UUID

    init(collectionId: String, name: String, poster: String?, count: Int?, id: UUID = .init()) {
        self.collectionId = collectionId
        self.name = name
        self.poster = poster
        self.count = count
        self.id = id
    }
}
