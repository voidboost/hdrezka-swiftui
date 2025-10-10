import Foundation

struct MovieBest: Identifiable, Hashable {
    let name: String
    let genres: [MovieGenre]
    let years: [MovieYear]
    let id: UUID

    init(name: String, genres: [MovieGenre], years: [MovieYear], id: UUID = .init()) {
        self.name = name
        self.genres = genres
        self.years = years
        self.id = id
    }
}
