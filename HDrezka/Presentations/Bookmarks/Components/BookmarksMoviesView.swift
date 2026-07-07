import SwiftUI

struct BookmarksMoviesView: View {
    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: .infinity), spacing: 18, alignment: .topLeading),
    ]

    @Environment(BookmarksViewModel.self) private var viewModel

    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 18) {
                if let movies = viewModel.bookmarkState.data, !movies.isEmpty {
                    ForEach(movies) { movie in
                        CardView(movie: movie, draggable: true)
                            .equatable()
                            .contextMenu {
                                Button {
                                    if let movieId = movie.movieId.id {
                                        viewModel.removeFromBookmarks(movies: [movieId])
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

            if viewModel.paginationState == .loading {
                LoadingPaginationStateView()
            }
        }
        .scrollIndicators(.visible, axes: .vertical)
        .onScrollTargetVisibilityChange(idType: MovieSimple.ID.self) { onScreenCards in
            if viewModel.paginationState == .idle,
               let movies = viewModel.bookmarkState.data,
               !movies.isEmpty,
               let last = movies.last,
               onScreenCards.contains(where: { $0 == last.id })
            {
                viewModel.loadMore()
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
            if let error = viewModel.bookmarkState.error {
                VStack(alignment: .center, spacing: 8) {
                    Text(error.localizedDescription)
                        .font(.system(.title, weight: .medium))
                        .lineLimit(nil)
                        .multilineTextAlignment(.center)

                    Button {
                        viewModel.load()
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
            } else if let movies = viewModel.bookmarkState.data, movies.isEmpty {
                VStack(alignment: .center, spacing: 8) {
                    Text(viewModel.selectedBookmark == nil ? String(localized: "key.bookmarks.select") : String(localized: "key.bookmarks.empty"))
                        .font(.system(.title, weight: .medium))
                        .lineLimit(nil)
                        .multilineTextAlignment(.center)

                    if viewModel.selectedBookmark != nil {
                        Button {
                            viewModel.load()
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
            } else if viewModel.bookmarkState == .loading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(18)
            }
        }
    }
}
