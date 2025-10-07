import SwiftUI

struct CategoriesTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack(path: Binding {
            appState.paths[.categories, default: []]
        } set: {
            appState.paths[.categories] = $0
        }) {
            CategoriesView().destinations()
        }
    }
}
