import SwiftUI

struct HomeTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack(path: Binding {
            appState.paths[.home, default: []]
        } set: {
            appState.paths[.home] = $0
        }) {
            HomeView().destinations()
        }
    }
}
