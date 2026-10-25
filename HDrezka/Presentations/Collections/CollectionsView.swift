import ComposableArchitecture
import Defaults
import SwiftUI

struct CollectionsView: View {
    private let title = String(localized: "key.collections")

    @Bindable var store: StoreOf<CollectionsFeature>

    private let columns = [
        GridItem(.adaptive(minimum: 250, maximum: .infinity), spacing: 18, alignment: .topLeading),
    ]

    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 18) {
                if let collections = store.collections.data, !collections.isEmpty {
                    ForEach(collections) { collection in
                        CollectionCardView(collection: collection)
                            .equatable()
                    }
                }
            }
            .scrollTargetLayout()
            .padding(.vertical, 18)
            .padding(.horizontal, 36)

            if store.pagination.state == .loading {
                LoadingPaginationStateView()
            }
        }
        .scrollIndicators(.visible, axes: .vertical)
        .onScrollNearEnd(of: store.collections.data, threshold: 8, isEnabled: store.pagination.state == .idle) {
            store.send(.loadMore)
        }
        .viewModifier { view in
            if #available(macOS 26, *) {
                view.scrollEdgeEffectStyle(.soft, for: .all)
            } else {
                view
            }
        }
        .dataStateOverlay(store.collections, empty: String(localized: "key.collections.empty")) {
            store.send(.reload)
        }
        .transition(.opacity)
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    store.send(.reload)
                } label: {
                    Image(systemName: "arrow.trianglehead.clockwise")
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(store.collections.data?.isEmpty != false)
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
        .background(.background)
    }
}
