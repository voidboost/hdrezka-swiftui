import Foundation

struct PersonSimple: Codable, Named {
    let personId: String
    let name: String
    let photo: String
    let id: UUID

    init(personId: String, name: String, photo: String, id: UUID = .init()) {
        self.personId = personId
        self.name = name
        self.photo = photo
        self.id = id
    }
}
