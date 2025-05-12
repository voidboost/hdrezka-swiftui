import Foundation

struct MovieRating: Identifiable, Codable, Hashable {
    let value: Float
    let votesCount: String
    let link: String
    let id: UUID

    init?(value: Float?, votesCount: String?, link: String?, id: UUID = .init()) {
        guard let value, let votesCount, let link else { return nil }

        self.value = value
        self.votesCount = votesCount
        self.link = link
        self.id = id
    }
}
