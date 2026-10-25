import Foundation

struct PersonSimple: Codable, Named {
    let personId: String
    let name: String
    let photo: String
    var id = UUID()
}
