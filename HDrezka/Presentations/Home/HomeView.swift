import ComposableArchitecture
import SwiftUI

struct HomeView: View {
    private let title = String(localized: "key.home")

    @Bindable var store: StoreOf<HomeFeature>

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 18) {
                if let categories = store.categories.data, !categories.isEmpty {
                    ForEach(categories) { category in
                        HomeSectionView(category: category)
                            .equatable()

                        if category.category != Categories.allCases.last {
                            Divider().padding(.horizontal, 36)
                        }
                    }
                }
            }
            .scrollTargetLayout()
            .padding(.vertical, 18)

            if let error = store.paginationState.error {
                ErrorPaginationStateView(error) {
                    store.send(.loadMore(reset: true))
                }
            } else if store.paginationState == .loading {
                LoadingPaginationStateView()
            }
        }
        .scrollIndicators(.visible, axes: .vertical)
        .onScrollNearEnd(of: store.categories.data, isEnabled: store.paginationState == .idle) {
            store.send(.loadMore())
        }
        .viewModifier { view in
            if #available(macOS 26, *) {
                view.scrollEdgeEffectStyle(.soft, for: .all)
            } else {
                view
            }
        }
        .dataStateOverlay(store.categories, empty: String(localized: "key.home.empty")) {
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
                .disabled(store.categories.data?.isEmpty != false)
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    store.send(.seriesUpdatesTapped)
                } label: {
                    Image(systemName: "bell")
                }
                .disabled(store.categories.data == nil)
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
        .background(.background)
        .sheet(item: $store.scope(state: \.seriesUpdates, action: \.seriesUpdates)) { store in
            SeriesUpdatesSheetView(store: store)
        }
    }
}
