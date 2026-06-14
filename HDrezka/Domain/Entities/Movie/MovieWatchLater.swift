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
    let id: UUID

    init(watchLaterId: String, name: String, cover: String, details: String, watchingInfo: String, date: String, buttonText: String?, dataId: String, watched: Bool, id: UUID = .init()) {
        self.watchLaterId = watchLaterId
        self.name = name
        self.cover = cover
        self.details = details
        self.watchingInfo = watchingInfo
        self.date = date
        self.buttonText = buttonText
        self.dataId = dataId
        self.watched = watched
        self.id = id
    }
}
