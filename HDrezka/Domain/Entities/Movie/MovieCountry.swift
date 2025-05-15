import Foundation

struct MovieCountry: Codable, Named {
    let name: String
    let countryId: String
    let id: UUID

    init(name: String, countryId: String, id: UUID = .init()) {
        self.name = name
        self.countryId = countryId
        self.id = id
    }
}
