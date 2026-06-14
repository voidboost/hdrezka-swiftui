import Foundation

struct MovieYear: Identifiable, Hashable {
    let name: String
    let year: Int
    let id: UUID

    init(name: String, year: Int, id: UUID = .init()) {
        self.name = name
        self.year = year
        self.id = id
    }
}
