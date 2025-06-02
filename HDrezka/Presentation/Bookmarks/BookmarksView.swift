import Combine
import Defaults
import FactoryKit
import SwiftUI

struct BookmarksView: View {
    @StateObject private var vm = BookmarksViewModel()
        
    @Default(.isLoggedIn) private var isLoggedIn

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: .infinity), spacing: 18, alignment: .topLeading)
    ]
    
    private let title = String(localized: "key.bookmarks")
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Group {
                if let error = vm.bookmarksState.error {
                    VStack(alignment: .center, spacing: 8) {
                        Text(error.localizedDescription)
                            .font(.system(size: 17, weight: .medium))
                            .lineLimit(nil)
                            .multilineTextAlignment(.center)
                            
                        Button {
                            vm.getBookmarks(reset: true)
                        } label: {
                            Text("key.retry")
                                .font(.system(size: 13))
                                .foregroundStyle(.accent)
                                .highlightOnHover()
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut("r", modifiers: .command)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 52)
                    .padding(18)
                } else if let bookmarks = vm.bookmarksState.data {
                    if bookmarks.isEmpty {
                        VStack(alignment: .center, spacing: 8) {
                            Text("key.bookmark.empty")
                                .font(.system(size: 17, weight: .medium))
                                .lineLimit(nil)
                                .multilineTextAlignment(.center)
                   
                            Button {
                                vm.isCreateBookmarkPresented = true
                            } label: {
                                Text("key.create")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.accent)
                                    .highlightOnHover()
                            }
                            .buttonStyle(.plain)
                            .keyboardShortcut("n", modifiers: .command)
                   
                            Button {
                                vm.getBookmarks(reset: true)
                            } label: {
                                Text("key.retry")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.accent)
                                    .highlightOnHover()
                            }
                            .buttonStyle(.plain)
                            .keyboardShortcut("r", modifiers: .command)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 52)
                        .padding(18)
                    } else {
                        List(selection: $vm.selectedBookmark) {
                            ForEach(bookmarks) { bookmark in
                                Text(bookmark.name)
                                    .font(.system(size: 15))
                                    .lineLimit(1)
                                    .badge(
                                        Text(bookmark.count.description)
                                            .monospacedDigit()
                                    )
                                    .viewModifier { view in
                                        if #available(macOS 14, *) {
                                            view.contentTransition(.numericText(value: Double(bookmark.count)))
                                        } else {
                                            view
                                        }
                                    }
                                    .tag(bookmark.bookmarkId)
                                    .padding(7)
                                    .listRowInsets(.init())
                                    .contextMenu {
                                        Button {
                                            vm.renameBookmark = bookmark
                                        } label: {
                                            Text("key.rename")
                                        }
                                            
                                        Button {
                                            vm.deleteBookmarksCategory(bookmark: bookmark)
                                        } label: {
                                            Text("key.delete")
                                        }
                                    }
                                    .viewModifier { view in
                                        if vm.selectedBookmark != bookmark.bookmarkId {
                                            view.dropDestination(for: MovieSimple.self) { movies, _ in
                                                if !movies.isEmpty, !movies.compactMap(\.movieId.id).isEmpty {
                                                    vm.moveBetweenBookmarks(movies: movies, bookmark: bookmark)
                                                    
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
                                            vm.deleteBookmarksCategory(bookmark: bookmark)
                                        } label: {
                                            Image(systemName: "trash")
                                                .font(.system(size: 15))
                                        }
                                        .tint(.accentColor)
                                            
                                        Button {
                                            vm.renameBookmark = bookmark
                                        } label: {
                                            Image(systemName: "pencil")
                                                .font(.system(size: 15))
                                        }
                                        .tint(.secondary)
                                    }
                            }
                            .onMove { fromOffsets, toOffset in
                                vm.reorderBookmarksCategories(fromOffsets: fromOffsets, toOffset: toOffset)
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
            
            if let error = vm.bookmarkState.error {
                VStack(alignment: .center, spacing: 8) {
                    Text(error.localizedDescription)
                        .font(.system(size: 20, weight: .medium))
                        .lineLimit(nil)
                        .multilineTextAlignment(.center)
                            
                    Button {
                        vm.load()
                    } label: {
                        Text("key.retry")
                            .font(.system(size: 15))
                            .foregroundStyle(.accent)
                            .highlightOnHover()
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut("r", modifiers: .command)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 52)
                .padding(18)
            } else if let movies = vm.bookmarkState.data {
                if movies.isEmpty {
                    VStack(alignment: .center, spacing: 8) {
                        Text(vm.selectedBookmark == -1 ? String(localized: "key.bookmarks.select") : String(localized: "key.bookmarks.empty"))
                            .font(.system(size: 20, weight: .medium))
                            .lineLimit(nil)
                            .multilineTextAlignment(.center)
                   
                        if vm.selectedBookmark != -1 {
                            Button {
                                vm.load()
                            } label: {
                                Text("key.retry")
                                    .font(.system(size: 15))
                                    .foregroundStyle(.accent)
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
                                                    vm.removeFromBookmarks(movies: [movieId])
                                                }
                                            } label: {
                                                Text("key.delete")
                                            }
                                            .disabled(movie.movieId.id == nil)
                                        }
                                        .task {
                                            if movies.last == movie, vm.paginationState == .idle {
                                                vm.loadMore()
                                            }
                                        }
                                }
                            }
                            .padding(.top, 52)
                            .padding(18)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .scrollIndicators(.never)
                            
                        if vm.paginationState == .loading {
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
            if let bookmarks = vm.bookmarksState.data, !bookmarks.isEmpty {
                if !(vm.bookmarkState.data?.isEmpty ?? true) || vm.selectedBookmark == -1 {
                    Button {
                        vm.getBookmarks(reset: true)
                    } label: {
                        Image(systemName: "arrow.trianglehead.clockwise")
                    }
                    .buttonStyle(NavbarButtonStyle(width: 30, height: 22))
                    .keyboardShortcut("r", modifiers: .command)
                }
                
                Button {
                    vm.isCreateBookmarkPresented = true
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(NavbarButtonStyle(width: 22, height: 22))
                .keyboardShortcut("n", modifiers: .command)
            }
        }, toolbar: {
            if vm.bookmarkState != .loading, vm.selectedBookmark != -1 {
                Image(systemName: "line.3.horizontal.decrease.circle")

                Picker("key.filter.select", selection: $vm.filter) {
                    ForEach(BookmarkFilters.allCases) { f in
                        Text(f.rawValue).tag(f)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .viewModifier { view in
                    if #available(macOS 14, *) {
                        view
                            .buttonStyle(.accessoryBar)
                            .controlSize(.large)
                    } else {
                        view
                    }
                }
                .background(.tertiary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .contentShape(RoundedRectangle(cornerRadius: 6))
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.tertiary.opacity(0.2), lineWidth: 1)
                }
               
                Divider()
                    .padding(.vertical, 18)

                Picker("key.genre.select", selection: $vm.genre) {
                    ForEach(Genres.allCases) { g in
                        Text(g.rawValue).tag(g)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .viewModifier { view in
                    if #available(macOS 14, *) {
                        view
                            .buttonStyle(.accessoryBar)
                            .controlSize(.large)
                    } else {
                        view
                    }
                }
                .background(.tertiary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .contentShape(RoundedRectangle(cornerRadius: 6))
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.tertiary.opacity(0.2), lineWidth: 1)
                }
            }
        })
        .customOnChange(of: vm.selectedBookmark) {
            if vm.selectedBookmark != -1 {
                vm.load()
            }
        }
        .customOnChange(of: vm.isCreateBookmarkPresented) {
            if !vm.isCreateBookmarkPresented {
                vm.getBookmarks(reset: true)
            }
        }
        .customOnChange(of: vm.renameBookmark) {
            if vm.renameBookmark == nil {
                vm.getBookmarks(reset: true)
            }
        }
        .customOnChange(of: vm.filter) {
            vm.load()
        }
        .customOnChange(of: vm.genre) {
            vm.load()
        }
        .load(isLoggedIn) {
            switch vm.bookmarksState {
            case .data:
                break
            default:
                vm.getBookmarks()
            }
        }
        .alert("key.ops", isPresented: $vm.isErrorPresented) {
            Button(role: .cancel) {} label: { Text("key.ok") }
        } message: {
            if let error = vm.error {
                Text(error.localizedDescription)
            }
        }
        .dialogSeverity(.critical)
        .sheet(item: $vm.renameBookmark) { bookmark in
            RenameBookmarkSheetView(bookmark: bookmark)
        }
        .sheet(isPresented: $vm.isCreateBookmarkPresented) {
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
