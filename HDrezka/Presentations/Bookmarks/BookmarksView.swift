import ComposableArchitecture
import SwiftUI

struct BookmarksView: View {
    private let title = String(localized: "key.bookmarks")

    @State private var store: StoreOf<BookmarksFeature>

    init(store: StoreOf<BookmarksFeature> = Store(initialState: BookmarksFeature.State()) { BookmarksFeature() }) {
        _store = State(initialValue: store)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            BookmarksListView()
                .environment(store)

            Divider()

            BookmarksMoviesView()
                .environment(store)
        }
        .transition(.opacity)
        .navigationTitle(title)
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button {
                    store.send(.reloadBookmarks(reset: true))
                } label: {
                    Image(systemName: "arrow.trianglehead.clockwise")
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(store.bookmarks.data?.isEmpty != false || (store.movies.data?.isEmpty != false && store.selectedBookmark != nil))

                Button {
                    store.isCreateBookmarkPresented = true
                } label: {
                    Image(systemName: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
                .disabled(store.bookmarks.data?.isEmpty != false)
            }

            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Picker("key.filter.select", selection: $store.filter) {
                        ForEach(BookmarkFilters.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.inline)

                    Picker("key.genre.select", selection: $store.genre) {
                        ForEach(Genres.allCases) { genre in
                            Text(genre.rawValue).tag(genre)
                        }
                    }
                    .pickerStyle(.inline)
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                }
                .menuStyle(.button)
                .menuIndicator(.hidden)
                .disabled(store.movies == .loading || store.selectedBookmark == nil)
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .dialogSeverity(.critical)
        .sheet(item: $store.renameBookmark) { bookmark in
            RenameBookmarkSheetView(bookmark: bookmark)
        }
        .sheet(isPresented: $store.isCreateBookmarkPresented) {
            CreateBookmarkSheetView()
        }
        .background(.background)
    }
}
