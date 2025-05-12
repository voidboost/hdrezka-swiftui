import Foundation

struct MovieType: Identifiable, Hashable {
    let name: String
    let typeId: String
    let genres: [MovieGenre]
    let best: MovieBest
    let id: UUID

    init(name: String, typeId: String, genres: [MovieGenre], best: MovieBest, id: UUID = .init()) {
        self.name = name
        self.typeId = typeId
        self.genres = genres
        self.best = best
        self.id = id
    }
}
