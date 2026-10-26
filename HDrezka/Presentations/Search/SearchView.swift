import ComposableArchitecture
import Defaults
import SwiftUI

struct SearchView: View {
    @Bindable var store: StoreOf<SearchFeature>

    var body: some View {
        SearchResultsView(store: store)
            .searchable(text: $store.query, placement: .toolbar)
            .transition(.opacity)
            .navigationTitle(store.title)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button {
                        store.send(.reload)
                    } label: {
                        Image(systemName: "arrow.trianglehead.clockwise")
                    }
                    .keyboardShortcut("r", modifiers: .command)
                    .disabled(store.movies.data?.isEmpty != false)
                }
            }
            .background(.background)
            .onAppear {
                store.send(.onAppear)
            }
    }
}

private struct SearchResultsView: View {
    let store: StoreOf<SearchFeature>

    var body: some View {
        MoviesGridView(store.movies.data, pagination: store.pagination.state) {
            store.send(.loadMore)
        }
        .viewModifier { view in
            if #available(macOS 26, *) {
                view.scrollEdgeEffectStyle(.soft, for: .all)
            } else {
                view
            }
        }
        .dataStateOverlay(store.movies, empty: String(localized: "key.nothing_found"), String(localized: "key.search.empty"), retriesWhenEmpty: false) {
            store.send(.reload)
        }
    }
}
