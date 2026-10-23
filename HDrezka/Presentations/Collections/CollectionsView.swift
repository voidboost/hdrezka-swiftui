import ComposableArchitecture
import Defaults
import SwiftUI

struct CollectionsView: View {
    private let title = String(localized: "key.collections")

    @State private var store: StoreOf<CollectionsFeature>

    init(store: StoreOf<CollectionsFeature> = Store(initialState: CollectionsFeature.State()) { CollectionsFeature() }) {
        _store = State(initialValue: store)
    }

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

            if store.paginationState == .loading {
                LoadingPaginationStateView()
            }
        }
        .scrollIndicators(.visible, axes: .vertical)
        .onScrollTargetVisibilityChange(idType: MoviesCollection.ID.self) { onScreenCards in
            if store.paginationState == .idle,
               let collections = store.collections.data,
               collections.suffix(8).contains(where: { onScreenCards.contains($0.id) })
            {
                store.send(.loadMore)
            }
        }
        .viewModifier { view in
            if #available(macOS 26, *) {
                view.scrollEdgeEffectStyle(.soft, for: .all)
            } else {
                view
            }
        }
        .overlay {
            if let error = store.collections.error {
                ErrorStateView(error) {
                    store.send(.reload)
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 36)
            } else if let collections = store.collections.data, collections.isEmpty {
                EmptyStateView(String(localized: "key.collections.empty")) {
                    store.send(.reload)
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 36)
            } else if store.collections == .loading {
                LoadingStateView()
                    .padding(.vertical, 18)
                    .padding(.horizontal, 36)
            }
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
