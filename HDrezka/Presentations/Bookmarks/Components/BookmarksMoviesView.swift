import ComposableArchitecture
import SwiftUI

struct BookmarksMoviesView: View {
    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: .infinity), spacing: 18, alignment: .topLeading),
    ]

    @Environment(StoreOf<BookmarksFeature>.self) private var store

    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 18) {
                if let movies = store.movies.data, !movies.isEmpty {
                    ForEach(movies) { movie in
                        CardView(movie: movie, draggable: true)
                            .equatable()
                            .contextMenu {
                                Button {
                                    if let movieId = movie.movieId.id {
                                        store.send(.removeMovies([movieId]))
                                    }
                                } label: {
                                    Text("key.delete")
                                }
                                .disabled(movie.movieId.id == nil)
                            }
                    }
                }
            }
            .padding(18)
            .scrollTargetLayout()

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
                view.scrollEdgeEffectStyle(.hard, for: .all)
            } else {
                view
            }
        }
        .overlay {
            if let error = store.movies.error {
                VStack(alignment: .center, spacing: 8) {
                    Text(error.localizedDescription)
                        .font(.system(.title, weight: .medium))
                        .lineLimit(nil)
                        .multilineTextAlignment(.center)

                    Button {
                        store.send(.reloadMovies)
                    } label: {
                        Text("key.retry")
                            .font(.title3)
                            .foregroundStyle(Color.accentColor)
                    }
                    .buttonStyle(.accessoryBar)
                    .keyboardShortcut("r", modifiers: .command)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(18)
            } else if let movies = store.movies.data, movies.isEmpty {
                VStack(alignment: .center, spacing: 8) {
                    Text(store.selectedBookmark == nil ? String(localized: "key.bookmarks.select") : String(localized: "key.bookmarks.empty"))
                        .font(.system(.title, weight: .medium))
                        .lineLimit(nil)
                        .multilineTextAlignment(.center)

                    if store.selectedBookmark != nil {
                        Button {
                            store.send(.reloadMovies)
                        } label: {
                            Text("key.retry")
                                .font(.title3)
                                .foregroundStyle(Color.accentColor)
                        }
                        .buttonStyle(.accessoryBar)
                        .keyboardShortcut("r", modifiers: .command)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(18)
            } else if store.movies.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(18)
            }
        }
    }
}
