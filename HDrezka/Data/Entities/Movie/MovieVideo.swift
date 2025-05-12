import Foundation
import OrderedCollections

struct MovieVideo: Identifiable, Codable, Hashable {
    let videoMap: OrderedDictionary<String, String>
    let subtitles: [MovieSubtitles]
    let needPremium: Bool
    let thumbnails: String?
    let id: UUID

    init(videoMap: OrderedDictionary<String, String>, subtitles: [MovieSubtitles], needPremium: Bool, thumbnails: String?, id: UUID = .init()) {
        self.videoMap = videoMap
        self.subtitles = subtitles
        self.needPremium = needPremium
        self.thumbnails = thumbnails
        self.id = id
    }

    func getMaxQuality() -> String? {
        guard let last = getAvailableQualities().last else { return nil }

        return videoMap[last]
    }

    func getClosestTo(quality: String) -> String? {
        videoMap[quality] ?? getMaxQuality()
    }

    func getAvailableQualities() -> [String] {
        Array(videoMap.filter { !$1.isEmpty && $1 != "null" }.keys)
    }

    func getLockedQualities() -> [String] {
        Array(videoMap.filter { $1.isEmpty || $1 == "null" }.keys)
    }
}
