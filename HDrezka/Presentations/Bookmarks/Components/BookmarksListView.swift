import ComposableArchitecture
import SwiftUI

struct BookmarksListView: View {
    @Environment(StoreOf<BookmarksFeature>.self) private var store

    var body: some View {
        List(selection: Binding {
            store.selectedBookmark
        } set: { selectedBookmark in
            guard let selectedBookmark else { return }

            store.selectedBookmark = selectedBookmark
        }) {
            if let bookmarks = store.bookmarks.data, !bookmarks.isEmpty {
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
                                store.send(.renameTapped(bookmark))
                            } label: {
                                Text("key.rename")
                            }

                            Button {
                                store.send(.deleteBookmark(bookmark))
                            } label: {
                                Text("key.delete")
                            }
                        }
                        .viewModifier { view in
                            if #available(macOS 26, *) {
                                view.dropDestination(for: MovieSimple.self, isEnabled: store.selectedBookmark != bookmark.bookmarkId) { movies, _ in
                                    if !movies.isEmpty, !movies.compactMap(\.movieId.id).isEmpty {
                                        store.send(.moveMovies(movies, to: bookmark))
                                    }
                                }
                            } else if store.selectedBookmark != bookmark.bookmarkId {
                                view.dropDestination(for: MovieSimple.self) { movies, _ in
                                    if !movies.isEmpty, !movies.compactMap(\.movieId.id).isEmpty {
                                        store.send(.moveMovies(movies, to: bookmark))

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
                                store.send(.deleteBookmark(bookmark))
                            } label: {
                                Image(systemName: "trash")
                                    .font(.title3)
                            }
                            .tint(.accentColor)

                            Button {
                                store.send(.renameTapped(bookmark))
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.title3)
                            }
                            .tint(.secondary)
                        }
                }
                .onMove { fromOffsets, toOffset in
                    store.send(.reorderBookmarks(fromOffsets: fromOffsets, toOffset: toOffset))
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
            if let error = store.bookmarks.error {
                VStack(alignment: .center, spacing: 8) {
                    Text(error.localizedDescription)
                        .font(.system(.title2, weight: .medium))
                        .lineLimit(nil)
                        .multilineTextAlignment(.center)

                    Button {
                        store.send(.reloadBookmarks(reset: true))
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
            } else if let bookmarks = store.bookmarks.data, bookmarks.isEmpty {
                VStack(alignment: .center, spacing: 8) {
                    Text("key.bookmark.empty")
                        .font(.system(.title2, weight: .medium))
                        .lineLimit(nil)
                        .multilineTextAlignment(.center)

                    Button {
                        store.send(.createTapped)
                    } label: {
                        Text("key.create")
                            .font(.body)
                            .foregroundStyle(Color.accentColor)
                    }
                    .buttonStyle(.accessoryBar)
                    .keyboardShortcut("n", modifiers: .command)

                    Button {
                        store.send(.reloadBookmarks(reset: true))
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
            } else if store.bookmarks.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(18)
            }
        }
        .frame(width: 200)
    }
}
