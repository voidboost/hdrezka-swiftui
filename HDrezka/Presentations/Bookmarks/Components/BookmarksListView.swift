import SwiftUI

struct BookmarksListView: View {
    @Environment(BookmarksViewModel.self) private var viewModel

    var body: some View {
        List(selection: Binding {
            viewModel.selectedBookmark
        } set: { selectedBookmark in
            guard let selectedBookmark else { return }

            viewModel.selectedBookmark = selectedBookmark
        }) {
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
    }
}
