import Foundation

struct MovieVoiceActing: Identifiable, Hashable, Codable {
    let name: String
    let voiceId: String
    let translatorId: String
    let isCamrip: String
    let isAds: String
    let isDirector: String
    let isPremium: Bool
    let isSelected: Bool
    let url: String?
    var id = UUID()
}
