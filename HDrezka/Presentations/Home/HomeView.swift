import ComposableArchitecture
import SwiftUI

struct HomeView: View {
    private let title = String(localized: "key.home")

    @State private var store: StoreOf<HomeFeature>

    init(store: StoreOf<HomeFeature> = Store(initialState: HomeFeature.State()) { HomeFeature() }) {
        _store = State(initialValue: store)
    }

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
        .onScrollTargetVisibilityChange(idType: Category.ID.self) { onScreenCategories in
            if store.paginationState == .idle,
               let categories = store.categories.data,
               !categories.isEmpty,
               let last = categories.last,
               onScreenCategories.contains(where: { $0 == last.id })
            {
                store.send(.loadMore())
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
            if let error = store.categories.error {
                ErrorStateView(error) {
                    store.send(.reload)
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 36)
            } else if let categories = store.categories.data, categories.isEmpty {
                EmptyStateView(String(localized: "key.home.empty")) {
                    store.send(.reload)
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 36)
            } else if store.categories == .loading {
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
        .navigationDestination(item: $store.movieDestination) {
            DetailsView(movie: $0)
        }
    }
}
