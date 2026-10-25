import Foundation

struct MovieType: Identifiable, Hashable {
    let name: String
    let typeId: String
    let genres: [MovieGenre]
    let best: MovieBest
    var id = UUID()
}
