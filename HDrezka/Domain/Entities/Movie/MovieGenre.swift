import Foundation

struct MovieGenre: Codable, Named {
    let name: String
    let genreId: String
    var id = UUID()
}
