import SwiftUI

struct BookmarksTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack(path: Binding {
            appState.paths[.bookmarks, default: []]
        } set: {
            appState.paths[.bookmarks] = $0
        }) {
            BookmarksView().destinations()
        }
    }
}
