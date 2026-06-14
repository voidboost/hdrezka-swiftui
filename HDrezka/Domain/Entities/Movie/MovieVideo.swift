import Foundation
import OrderedCollections

struct MovieVideo: Identifiable, Codable, Hashable {
    let videos: [Video]
    let subtitles: [MovieSubtitles]
    let needPremium: Bool
    let thumbnails: String?
    let id: UUID

    init(videos: [Video], subtitles: [MovieSubtitles], needPremium: Bool, thumbnails: String?, id: UUID = .init()) {
        self.videos = videos
        self.subtitles = subtitles
        self.needPremium = needPremium
        self.thumbnails = thumbnails
        self.id = id
    }

    func getMaxQuality() -> [URL]? {
        videos.last(where: { !$0.needAccount && !$0.needPremium })?.urls
    }

    func getClosestTo(quality: String) -> [URL]? {
        videos.first(where: { $0.quality == quality })?.urls ?? getMaxQuality()
    }

    func getAvailableQualities() -> [String] {
        videos.filter { !$0.needAccount && !$0.needPremium }.map(\.quality)
    }

    func getAccountQualities() -> [String] {
        videos.filter { $0.needAccount && !$0.needPremium }.map(\.quality)
    }

    func getPremiumQualities() -> [String] {
        videos.filter { !$0.needAccount && $0.needPremium }.map(\.quality)
    }

    func getLockedQualities() -> [String] {
        videos.filter { $0.needAccount && $0.needPremium }.map(\.quality)
    }

    struct Video: Identifiable, Codable, Hashable {
        let quality: String
        let urls: [URL]
        let needAccount: Bool
        let needPremium: Bool
        let id: UUID

        init(quality: String, urls: [URL], needAccount: Bool, needPremium: Bool, id: UUID = .init()) {
            self.quality = quality
            self.urls = urls
            self.needAccount = needAccount
            self.needPremium = needPremium
            self.id = id
        }
    }
}
