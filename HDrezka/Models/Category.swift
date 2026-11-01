import Foundation

struct Category: Identifiable, Hashable {
    let category: Categories
    let title: String
    let movies: [MovieSimple]
    var id = UUID()
}
