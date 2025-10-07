import SwiftUI

struct CollectionsTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack(path: Binding {
            appState.paths[.collections, default: []]
        } set: {
            appState.paths[.collections] = $0
        }) {
            CollectionsView().destinations()
        }
    }
}
