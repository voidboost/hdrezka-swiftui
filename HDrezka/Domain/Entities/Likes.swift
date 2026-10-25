import Foundation

struct Likes: Identifiable, Hashable {
    let likes: [Like]
    let id: UUID

    init(likes: [Like] = [], id: UUID = .init()) {
        self.likes = likes
        self.id = id
    }
}

struct Like: Identifiable, Hashable {
    let photo: String
    let name: String
    var id = UUID()
}
