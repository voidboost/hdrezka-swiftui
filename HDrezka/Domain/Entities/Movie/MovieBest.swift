import Foundation

struct MovieBest: Identifiable, Hashable {
    let name: String
    let genres: [MovieGenre]
    let years: [MovieYear]
    var id = UUID()
}
