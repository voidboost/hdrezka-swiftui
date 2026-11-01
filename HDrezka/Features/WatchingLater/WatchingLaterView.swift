import ComposableArchitecture
import SwiftUI

struct WatchingLaterView: View {
    private let title = String(localized: "key.watching_later")

    @Bindable var store: StoreOf<WatchingLaterFeature>

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: .infinity), spacing: 18, alignment: .topLeading),
    ]

    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 18) {
                if let movies = store.movies.data, !movies.isEmpty {
                    ForEach(movies) { movie in
                        WatchingLaterCardView(movie: movie)
                            .equatable()
                            .contextMenu {
                                Button {
                                    store.send(.switchWatched(movie))
                                } label: {
                                    Text(movie.watched ? String(localized: "key.mark.unwatched") : String(localized: "key.mark.watched"))
                                }

                                Button {
                                    store.send(.remove(movie))
                                } label: {
                                    Text("key.delete")
                                }
                            }
                    }
                }
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 36)
        }
        .scrollIndicators(.visible, axes: .vertical)
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
                EmptyStateView(String(localized: "key.watching_later.empty"), String(localized: "key.watching_later.empty.description")) {
                    store.send(.reload)
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 36)
            } else if store.movies.isLoading {
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
                .disabled(store.movies.data?.isEmpty != false)
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .dialogSeverity(.critical)
        .background(.background)
    }
}
