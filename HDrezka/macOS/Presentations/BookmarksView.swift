import Combine
import Defaults
import FactoryKit
import SwiftUI

struct BookmarksView: View {
    private let title = String(localized: "key.bookmarks")

    @State private var viewModel = BookmarksViewModel()

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: .infinity), spacing: 18, alignment: .topLeading),
    ]

    @Default(.isLoggedIn) private var isLoggedIn

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            List(selection: $viewModel.selectedBookmark) {
                if let bookmarks = viewModel.bookmarksState.data, !bookmarks.isEmpty {
                    ForEach(bookmarks) { bookmark in
                        Text(bookmark.name)
                            .font(.title3)
                            .lineLimit(1)
                            .badge(Text(verbatim: "\(bookmark.count)").monospacedDigit())
                            .contentTransition(.numericText(value: Double(bookmark.count)))
                            .tag(bookmark.bookmarkId)
                            .padding(7)
                            .listRowInsets(.init())
                            .contextMenu {
                                Button {
                                    viewModel.renameBookmark = bookmark
                                } label: {
                                    Text("key.rename")
                                }

                                Button {
                                    viewModel.deleteBookmarksCategory(bookmark: bookmark)
                                } label: {
                                    Text("key.delete")
                                }
                            }
                            .viewModifier { view in
                                if viewModel.selectedBookmark != bookmark.bookmarkId {
                                    view.dropDestination(for: MovieSimple.self) { movies, _ in
                                        if !movies.isEmpty, !movies.compactMap(\.movieId.id).isEmpty {
                                            viewModel.moveBetweenBookmarks(movies: movies, toBookmark: bookmark)

                                            return true
                                        }

                                        return false
                                    }
                                } else {
                                    view
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button {
                                    viewModel.deleteBookmarksCategory(bookmark: bookmark)
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.title3)
                                }
                                .tint(.accentColor)

                                Button {
                                    viewModel.renameBookmark = bookmark
                                } label: {
                                    Image(systemName: "pencil")
                                        .font(.title3)
                                }
                                .tint(.secondary)
                            }
                    }
                    .onMove { fromOffsets, toOffset in
                        viewModel.reorderBookmarksCategories(fromOffsets: fromOffsets, toOffset: toOffset)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .environment(\.defaultMinListRowHeight, 0)
            .scrollIndicators(.visible, axes: .vertical)
            .viewModifier { view in
                if #available(macOS 26, *) {
                    view.scrollEdgeEffectStyle(.hard, for: .all)
                } else {
                    view
                }
            }
            .overlay {
                if let error = viewModel.bookmarksState.error {
                    VStack(alignment: .center, spacing: 8) {
                        Text(error.localizedDescription)
                            .font(.system(.title2, weight: .medium))
                            .lineLimit(nil)
                            .multilineTextAlignment(.center)

                        Button {
                            viewModel.getBookmarks(reset: true)
                        } label: {
                            Text("key.retry")
                                .font(.body)
                                .foregroundStyle(Color.accentColor)
                        }
                        .buttonStyle(.accessoryBar)
                        .keyboardShortcut("r", modifiers: .command)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(18)
                } else if let bookmarks = viewModel.bookmarksState.data, bookmarks.isEmpty {
                    VStack(alignment: .center, spacing: 8) {
                        Text("key.bookmark.empty")
                            .font(.system(.title2, weight: .medium))
                            .lineLimit(nil)
                            .multilineTextAlignment(.center)

                        Button {
                            viewModel.isCreateBookmarkPresented = true
                        } label: {
                            Text("key.create")
                                .font(.body)
                                .foregroundStyle(Color.accentColor)
                        }
                        .buttonStyle(.accessoryBar)
                        .keyboardShortcut("n", modifiers: .command)

                        Button {
                            viewModel.getBookmarks(reset: true)
                        } label: {
                            Text("key.retry")
                                .font(.body)
                                .foregroundStyle(Color.accentColor)
                        }
                        .buttonStyle(.accessoryBar)
                        .keyboardShortcut("r", modifiers: .command)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(18)
                } else if viewModel.bookmarksState == .loading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(18)
                }
            }
            .frame(width: 200)

            Divider()

            ScrollView(.vertical) {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 18) {
                    if let movies = viewModel.bookmarkState.data, !movies.isEmpty {
                        ForEach(movies) { movie in
                            CardView(movie: movie, draggable: true)
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
                if let movies = viewModel.bookmarkState.data,
                   !movies.isEmpty,
                   let last = movies.last,
                   onScreenCards.contains(where: { $0 == last.id }),
                   viewModel.paginationState == .idle
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
        .transition(.opacity)
        .navigationTitle(title)
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button {
                    viewModel.getBookmarks(reset: true)
                } label: {
                    Image(systemName: "arrow.trianglehead.clockwise")
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(viewModel.bookmarksState.data?.isEmpty != false || (viewModel.bookmarkState.data?.isEmpty != false && viewModel.selectedBookmark != nil))

                Button {
                    viewModel.isCreateBookmarkPresented = true
                } label: {
                    Image(systemName: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
                .disabled(viewModel.bookmarksState.data?.isEmpty != false)
            }

            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Picker("key.filter.select", selection: $viewModel.filter) {
                        ForEach(BookmarkFilters.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }

                    Picker("key.genre.select", selection: $viewModel.genre) {
                        ForEach(Genres.allCases) { genre in
                            Text(genre.rawValue).tag(genre)
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                }
                .disabled(viewModel.bookmarkState == .loading || viewModel.selectedBookmark == nil)
            }
        }
        .onChange(of: viewModel.selectedBookmark) {
            if viewModel.selectedBookmark != nil {
                viewModel.load()
            }
        }
        .onChange(of: viewModel.isCreateBookmarkPresented) {
            if !viewModel.isCreateBookmarkPresented {
                viewModel.getBookmarks(reset: true)
            }
        }
        .onChange(of: viewModel.renameBookmark) {
            if viewModel.renameBookmark == nil {
                viewModel.getBookmarks(reset: true)
            }
        }
        .onChange(of: viewModel.filter) {
            viewModel.load()
        }
        .onChange(of: viewModel.genre) {
            viewModel.load()
        }
        .onAppear {
            switch viewModel.bookmarksState {
            case .data:
                break
            default:
                viewModel.getBookmarks()
            }
        }
        .alert("key.ops", isPresented: $viewModel.isErrorPresented) {
            Button(role: .cancel) {} label: { Text("key.ok") }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
        .dialogSeverity(.critical)
        .sheet(item: $viewModel.renameBookmark) { bookmark in
            RenameBookmarkSheetView(bookmark: bookmark)
        }
        .sheet(isPresented: $viewModel.isCreateBookmarkPresented) {
            CreateBookmarkSheetView()
        }
        .background(.background)
    }
}
