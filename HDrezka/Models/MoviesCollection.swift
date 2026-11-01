import Foundation

struct MoviesCollection: Codable, Named {
    let collectionId: String
    let name: String
    let poster: String?
    let count: Int?
    var id = UUID()
}
