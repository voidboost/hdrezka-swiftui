import SwiftUI

struct SearchTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack(path: Binding {
            appState.paths[.search, default: []]
        } set: {
            appState.paths[.search] = $0
        }) {
            SearchView().destinations()
        }
    }
}
