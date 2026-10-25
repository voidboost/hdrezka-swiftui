import Foundation

struct MovieWatchLater: Identifiable, Hashable {
    let watchLaterId: String
    let name: String
    let cover: String
    let details: String
    let watchingInfo: String
    let date: String
    let buttonText: String?
    let dataId: String
    var watched: Bool
    var id = UUID()
}
