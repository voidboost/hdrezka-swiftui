import ComposableArchitecture
import Defaults
import SwiftUI

struct SearchView: View {
    @Bindable var store: StoreOf<SearchFeature>

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: .infinity), spacing: 18, alignment: .topLeading),
    ]

    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 18) {
                if let movies = store.movies.data, !movies.isEmpty {
                    ForEach(movies) { movie in
                        CardView(movie: movie)
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
        .onScrollTargetVisibilityChange(idType: MovieSimple.ID.self) { onScreenCards in
            if store.paginationState == .idle,
               let movies = store.movies.data,
               movies.suffix(12).contains(where: { onScreenCards.contains($0.id) })
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
            if let error = store.movies.error {
                ErrorStateView(error) {
                    store.send(.reload)
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 36)
            } else if let movies = store.movies.data, movies.isEmpty {
                EmptyStateView(String(localized: "key.nothing_found"), String(localized: "key.search.empty"))
                    .padding(.vertical, 18)
                    .padding(.horizontal, 36)
            } else if store.movies == .loading {
                LoadingStateView()
                    .padding(.vertical, 18)
                    .padding(.horizontal, 36)
            }
        }
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
