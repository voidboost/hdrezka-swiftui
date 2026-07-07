import SwiftUI

struct BookmarksView: View {
    private let title = String(localized: "key.bookmarks")

    @State private var viewModel = BookmarksViewModel()

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            BookmarksListView()
                .environment(viewModel)

            Divider()

            BookmarksMoviesView()
                .environment(viewModel)
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
                    .pickerStyle(.inline)

                    Picker("key.genre.select", selection: $viewModel.genre) {
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
