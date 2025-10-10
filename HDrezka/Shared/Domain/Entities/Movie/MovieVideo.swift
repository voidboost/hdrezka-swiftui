import Foundation
import OrderedCollections

struct MovieVideo: Identifiable, Codable, Hashable {
    let videoMap: OrderedDictionary<String, URL?>
    let subtitles: [MovieSubtitles]
    let needPremium: Bool
    let thumbnails: String?
    let id: UUID

    init(videoMap: OrderedDictionary<String, URL?>, subtitles: [MovieSubtitles], needPremium: Bool, thumbnails: String?, id: UUID = .init()) {
        self.videoMap = videoMap
        self.subtitles = subtitles
        self.needPremium = needPremium
        self.thumbnails = thumbnails
        self.id = id
    }

    func getMaxQuality() -> URL? {
        videoMap.compactMapValues { $0 }.values.last
    }

    func getClosestTo(quality: String) -> URL? {
        videoMap[quality] ?? getMaxQuality()
    }

    func getAvailableQualities() -> [String] {
        Array(videoMap.compactMapValues { $0 }.keys)
    }

    func getLockedQualities() -> [String] {
        Array(videoMap.filter { $1 == nil }.keys)
    }
}
