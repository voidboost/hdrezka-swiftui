import SwiftUI

struct WatchingLaterTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack(path: Binding {
            appState.paths[.watchingLater, default: []]
        } set: {
            appState.paths[.watchingLater] = $0
        }) {
            WatchingLaterView().destinations()
        }
    }
}
