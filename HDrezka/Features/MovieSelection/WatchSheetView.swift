import ComposableArchitecture
import FirebaseAnalytics
import SwiftUI

struct WatchSheetView: View {
    @Bindable var store: StoreOf<MovieSelectionFeature>

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        MovieSelectionSheet(store: store, icon: "videoprojector", description: "key.watch.description", showsSubtitles: false) {
            MovieSelectionActionButton("key.watch", isActive: store.selectedQuality != nil) {
                if let details = store.details, let selectedActing = store.selectedActing, let selectedQuality = store.selectedQuality, let movie = store.movie {
                    dismissWindow(id: Windows.player.id)

                    openWindow(
                        id: Windows.player.id,
                        value: PlayerData(details: details, selectedActing: selectedActing, seasons: store.seasons, selectedSeason: store.selectedSeason, selectedEpisode: store.selectedEpisode, selectedQuality: selectedQuality, movie: movie)
                    )

                    dismiss()
                }
            }
        }
        .analyticsScreen(name: "watch_sheet", class: "WatchSheetView")
    }
}
