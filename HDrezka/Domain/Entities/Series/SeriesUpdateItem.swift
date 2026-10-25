import Foundation

struct SeriesUpdateItem: Identifiable, Hashable {
    let seriesId: String
    let seriesName: String
    let season: String
    let releasedEpisode: String
    let chosenVoiceActing: String
    let isChosenVoiceActingPremium: Bool
    let tracked: Bool
    var id = UUID()
}
