import Foundation

struct MovieYear: Identifiable, Hashable {
    let name: String
    let year: Int
    var id = UUID()
}
