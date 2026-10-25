import Foundation

struct MovieFranchisePart: Identifiable, Codable, Hashable {
    let franchiseId: String?
    let name: String
    let year: String
    let rating: Float?
    let current: Bool
    let position: Int
    var id = UUID()
}
