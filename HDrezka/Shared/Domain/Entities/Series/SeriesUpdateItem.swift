import Foundation

struct SeriesUpdateItem: Identifiable, Hashable {
    let seriesId: String
    let seriesName: String
    let season: String
    let releasedEpisode: String
    let chosenVoiceActing: String
    let isChosenVoiceActingPremium: Bool
    let tracked: Bool
    let id: UUID

    init(seriesId: String, seriesName: String, season: String, releasedEpisode: String, chosenVoiceActing: String, isChosenVoiceActingPremium: Bool, tracked: Bool, id: UUID = .init()) {
        self.seriesId = seriesId
        self.seriesName = seriesName
        self.season = season
        self.releasedEpisode = releasedEpisode
        self.chosenVoiceActing = chosenVoiceActing
        self.isChosenVoiceActingPremium = isChosenVoiceActingPremium
        self.tracked = tracked
        self.id = id
    }
}
