import Foundation

struct Category: Identifiable, Hashable {
    let category: Categories
    let title: String
    let movies: [MovieSimple]
    let id: UUID

    init(category: Categories, title: String, movies: [MovieSimple], id: UUID = .init()) {
        self.category = category
        self.title = title
        self.movies = movies
        self.id = id
    }
}
