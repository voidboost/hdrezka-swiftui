import Foundation

struct MovieCountry: Codable, Named {
    let name: String
    let countryId: String
    var id = UUID()
}
