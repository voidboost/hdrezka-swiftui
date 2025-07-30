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
            Group {
                if let error = viewModel.bookmarksState.error {
                    VStack(alignment: .center, spacing: 8) {
                        Text(error.localizedDescription)
                            .font(.system(size: 17, weight: .medium))
                            .lineLimit(nil)
                            .multilineTextAlignment(.center)

                        Button {
                            viewModel.getBookmarks(reset: true)
                        } label: {
                            Text("key.retry")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.accentColor)
                                .highlightOnHover()
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut("r", modifiers: .command)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 52)
                    .padding(18)
                } else if let bookmarks = viewModel.bookmarksState.data {
                    if bookmarks.isEmpty {
                        VStack(alignment: .center, spacing: 8) {
                            Text("key.bookmark.empty")
                                .font(.system(size: 17, weight: .medium))
                                .lineLimit(nil)
                                .multilineTextAlignment(.center)

                            Button {
                                viewModel.isCreateBookmarkPresented = true
                            } label: {
                                Text("key.create")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.accentColor)
                                    .highlightOnHover()
                            }
                            .buttonStyle(.plain)
                            .keyboardShortcut("n", modifiers: .command)

                            Button {
                                viewModel.getBookmarks(reset: true)
                            } label: {
                                Text("key.retry")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.accentColor)
                                    .highlightOnHover()
                            }
                            .buttonStyle(.plain)
                            .keyboardShortcut("r", modifiers: .command)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 52)
                        .padding(18)
                    } else {
                        List(selection: $viewModel.selectedBookmark) {
                            ForEach(bookmarks) { bookmark in
                                Text(bookmark.name)
                                    .font(.system(size: 15))
                                    .lineLimit(1)
                                    .badge(
                                        Text(verbatim: "\(bookmark.count)")
                                            .monospacedDigit(),
                                    )
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
                                                    viewModel.moveBetweenBookmarks(movies: movies, bookmark: bookmark)

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
                                                .font(.system(size: 15))
                                        }
                                        .tint(.accentColor)

                                        Button {
                                            viewModel.renameBookmark = bookmark
                                        } label: {
                                            Image(systemName: "pencil")
                                                .font(.system(size: 15))
                                        }
                                        .tint(.secondary)
                                    }
                            }
                            .onMove { fromOffsets, toOffset in
                                viewModel.reorderBookmarksCategories(fromOffsets: fromOffsets, toOffset: toOffset)
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .environment(\.defaultMinListRowHeight, 0)
                        .padding(.top, 52)
                        .scrollIndicators(.never)
                    }
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 52)
                        .padding(18)
                }
            }
            .frame(width: 200)

            Divider()
                .padding(.top, 52)

            if let error = viewModel.bookmarkState.error {
                VStack(alignment: .center, spacing: 8) {
                    Text(error.localizedDescription)
                        .font(.system(size: 20, weight: .medium))
                        .lineLimit(nil)
                        .multilineTextAlignment(.center)

                    Button {
                        viewModel.load()
                    } label: {
                        Text("key.retry")
                            .font(.system(size: 15))
                            .foregroundStyle(Color.accentColor)
                            .highlightOnHover()
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut("r", modifiers: .command)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 52)
                .padding(18)
            } else if let movies = viewModel.bookmarkState.data {
                if movies.isEmpty {
                    VStack(alignment: .center, spacing: 8) {
                        Text(viewModel.selectedBookmark == -1 ? String(localized: "key.bookmarks.select") : String(localized: "key.bookmarks.empty"))
                            .font(.system(size: 20, weight: .medium))
                            .lineLimit(nil)
                            .multilineTextAlignment(.center)

                        if viewModel.selectedBookmark != -1 {
                            Button {
                                viewModel.load()
                            } label: {
                                Text("key.retry")
                                    .font(.system(size: 15))
                                    .foregroundStyle(Color.accentColor)
                                    .highlightOnHover()
                            }
                            .buttonStyle(.plain)
                            .keyboardShortcut("r", modifiers: .command)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 52)
                    .padding(18)
                } else {
                    VStack {
                        ScrollView(.vertical) {
                            LazyVGrid(columns: columns, alignment: .leading, spacing: 18) {
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
                            .padding(.top, 52)
                            .padding(18)
                            .scrollTargetLayout()
                        }
                        .scrollIndicators(.never)
                        .onScrollTargetVisibilityChange(idType: MovieSimple.ID.self) { onScreenCards in
                            if let last = movies.last, onScreenCards.contains(where: { $0 == last.id }), viewModel.paginationState == .idle {
                                viewModel.loadMore()
                            }
                        }

                        if viewModel.paginationState == .loading {
                            LoadingPaginationStateView()
                        }
                    }
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 52)
                    .padding(18)
            }
        }
        .navigationBar(title: title, showBar: true, navbar: {
            if let bookmarks = viewModel.bookmarksState.data, !bookmarks.isEmpty {
                if !(viewModel.bookmarkState.data?.isEmpty ?? true) || viewModel.selectedBookmark == -1 {
                    Button {
                        viewModel.getBookmarks(reset: true)
                    } label: {
                        Image(systemName: "arrow.trianglehead.clockwise")
                    }
                    .buttonStyle(NavbarButtonStyle(width: 30, height: 22))
                    .keyboardShortcut("r", modifiers: .command)
                }

                Button {
                    viewModel.isCreateBookmarkPresented = true
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(NavbarButtonStyle(width: 22, height: 22))
                .keyboardShortcut("n", modifiers: .command)
            }
        }, toolbar: {
            if viewModel.bookmarkState != .loading, viewModel.selectedBookmark != -1 {
                Image(systemName: "line.3.horizontal.decrease.circle")

                Picker("key.filter.select", selection: $viewModel.filter) {
                    ForEach(BookmarkFilters.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .buttonStyle(.accessoryBar)
                .controlSize(.large)
                .background(.tertiary.opacity(0.05))
                .clipShape(.rect(cornerRadius: 6))
                .contentShape(.rect(cornerRadius: 6))
                .overlay(.tertiary.opacity(0.2), in: .rect(cornerRadius: 6).stroke(lineWidth: 1))

                Divider()
                    .padding(.vertical, 18)

                Picker("key.genre.select", selection: $viewModel.genre) {
                    ForEach(Genres.allCases) { genre in
                        Text(genre.rawValue).tag(genre)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .buttonStyle(.accessoryBar)
                .background(.tertiary.opacity(0.05))
                .clipShape(.rect(cornerRadius: 6))
                .contentShape(.rect(cornerRadius: 6))
                .overlay(.tertiary.opacity(0.2), in: .rect(cornerRadius: 6).stroke(lineWidth: 1))
            }
        })
        .onChange(of: viewModel.selectedBookmark) {
            if viewModel.selectedBookmark != -1 {
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
        .task(id: isLoggedIn) {
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

enum BookmarkFilters: LocalizedStringKey, CaseIterable, Identifiable {
    case added = "key.filters.date"
    case year = "key.filters.year"
    case popular = "key.filters.popular"

    var id: BookmarkFilters { self }
}
