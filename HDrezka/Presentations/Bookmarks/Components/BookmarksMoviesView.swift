import ComposableArchitecture
import SwiftUI

struct BookmarksMoviesView: View {
    @Environment(StoreOf<BookmarksFeature>.self) private var store

    var body: some View {
        MoviesGridView(store.movies.data, pagination: store.pagination.state, padding: EdgeInsets(top: 18, leading: 18, bottom: 18, trailing: 18)) {
            store.send(.loadMore)
        } card: { movie in
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
        .viewModifier { view in
            if #available(macOS 26, *) {
                view.scrollEdgeEffectStyle(.hard, for: .all)
            } else {
                view
            }
        }
        .dataStateOverlay(
            store.movies,
            empty: store.selectedBookmark == nil ? String(localized: "key.bookmarks.select") : String(localized: "key.bookmarks.empty"),
            retriesWhenEmpty: store.selectedBookmark != nil,
            padding: EdgeInsets(top: 18, leading: 18, bottom: 18, trailing: 18)
        ) {
            store.send(.reloadMovies)
        }
    }
}
