import Foundation

struct Likes: Identifiable {
    let likes: [Like]
    let id: UUID

    init(likes: [Like] = [], id: UUID = .init()) {
        self.likes = likes
        self.id = id
    }
}

struct Like: Identifiable {
    let photo: String
    let name: String
    let id: UUID

    init(photo: String, name: String, id: UUID = .init()) {
        self.photo = photo
        self.name = name
        self.id = id
    }
}
