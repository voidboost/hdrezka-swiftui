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
    let id: UUID

    init(name: String, voiceId: String, translatorId: String, isCamrip: String, isAds: String, isDirector: String, isPremium: Bool, isSelected: Bool, url: String?, id: UUID = .init()) {
        self.name = name
        self.voiceId = voiceId
        self.translatorId = translatorId
        self.isCamrip = isCamrip
        self.isAds = isAds
        self.isDirector = isDirector
        self.isPremium = isPremium
        self.isSelected = isSelected
        self.url = url
        self.id = id
    }
}
