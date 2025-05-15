import Foundation

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
