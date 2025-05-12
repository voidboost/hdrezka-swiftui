import Foundation

struct MovieFranchisePart: Identifiable, Codable, Hashable {
    let franchiseId: String
    let name: String
    let year: String
    let rating: Float?
    let current: Bool
    let position: Int
    let id: UUID

    init(franchiseId: String, name: String, year: String, rating: Float?, current: Bool, position: Int, id: UUID = .init()) {
        self.franchiseId = franchiseId
        self.name = name
        self.year = year
        self.rating = rating
        self.current = current
        self.position = position
        self.id = id
    }
}
