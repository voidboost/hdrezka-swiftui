import Foundation

struct MovieList: Codable, Named {
    let name: String
    let listId: String
    let moviePosition: Int?
    let id: UUID

    init(name: String, listId: String, moviePosition: Int? = nil, id: UUID = .init()) {
        self.name = name
        self.listId = listId
        self.moviePosition = moviePosition
        self.id = id
    }
}
