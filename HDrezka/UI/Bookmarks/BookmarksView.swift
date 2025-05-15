import Combine
import Defaults
import FactoryKit
import SwiftUI

struct BookmarksView: View {
    @Injected(\.account) private var account

    @State private var subscriptions: Set<AnyCancellable> = []
    
    @State private var vm = BookmarksViewModel()
        
    @State private var selectedBookmark: Int = -1
    
    @State private var error: Error?
    @State private var isErrorPresented: Bool = false
    
    @State private var renameBookmark: Bookmark?
    @State private var isCreateBookmarkPresented: Bool = false
    
    @State private var selectedGenre = Genres.all
    @State private var filter = BookmarkFilters.added
    
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
                            selectedBookmark = -1
                            vm.reloadBookmarks()
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
                } else if var bookmarks = vm.bookmarksState.data {
                    if bookmarks.isEmpty {
                        VStack(alignment: .center, spacing: 8) {
                            Text("key.bookmark.empty")
                                .font(.system(size: 17, weight: .medium))
                                .lineLimit(nil)
                                .multilineTextAlignment(.center)
                   
                            Button {
                                isCreateBookmarkPresented = true
                            } label: {
                                Text("key.create")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.accent)
                                    .highlightOnHover()
                            }
                            .buttonStyle(.plain)
                            .keyboardShortcut("n", modifiers: .command)
                   
                            Button {
                                selectedBookmark = -1
                                vm.reloadBookmarks()
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
                        List(selection: $selectedBookmark) {
                            ForEach(bookmarks) { bookmark in
                                Text(bookmark.name)
                                    .font(.system(size: 15))
                                    .lineLimit(1)
                                    .badge(
                                        Text(bookmark.count.description)
                                            .monospacedDigit()
                                    )
                                    .contentTransition(.numericText(value: Double(bookmark.count)))
                                    .tag(bookmark.bookmarkId)
                                    .padding(7)
                                    .listRowInsets(.init())
                                    .contextMenu {
                                        Button {
                                            renameBookmark = bookmark
                                        } label: {
                                            Text("key.rename")
                                        }

                                        Button {
                                            account
                                                .deleteBookmarksCategory(id: bookmark.bookmarkId)
                                                .receive(on: DispatchQueue.main)
                                                .sink { completion in
                                                    guard case let .failure(error) = completion else { return }

                                                    self.error = error
                                                    self.isErrorPresented = true
                                                } receiveValue: { delete in
                                                    if delete {
                                                        bookmarks.removeAll(where: {
                                                            $0.bookmarkId == bookmark.bookmarkId
                                                        })
                                                        
                                                        withAnimation(.easeInOut) {
                                                            vm.bookmarksState = .data(bookmarks)
                                                        }

                                                        if selectedBookmark == bookmark.bookmarkId {
                                                            selectedBookmark = -1
                                                            vm.bookmarkState = .data([])
                                                        }
                                                    }
                                                }
                                                .store(in: &subscriptions)
                                        } label: {
                                            Text("key.delete")
                                        }
                                    }
                                    .if(selectedBookmark != bookmark.bookmarkId) { view in
                                        view.dropDestination(for: MovieSimple.self) { movies, _ in
                                            if !movies.isEmpty, !movies.compactMap(\.movieId.id).isEmpty {
                                                account
                                                    .moveBetweenBookmarks(movies: movies.compactMap(\.movieId.id), fromBookmarkUserCategory: selectedBookmark, toBookmarkUserCategory: bookmark.bookmarkId)
                                                    .receive(on: DispatchQueue.main)
                                                    .sink { completion in
                                                        guard case let .failure(error) = completion else { return }

                                                        self.error = error
                                                        self.isErrorPresented = true
                                                    } receiveValue: { moved in
                                                        withAnimation(.easeInOut) {
                                                            if var data = vm.bookmarkState.data {
                                                                data.removeAll(where: { movie in
                                                                    movies.contains(where: { movedMovie in
                                                                        movie.movieId == movedMovie.movieId
                                                                    })
                                                                })
                                                                
                                                                vm.bookmarkState = .data(data)
                                                            }
                                                            
                                                            if let from = bookmarks.firstIndex(where: { $0.bookmarkId == selectedBookmark }) {
                                                                bookmarks[from] -= 1
                                                            }
                                                                
                                                            if let to = bookmarks.firstIndex(where: { $0.bookmarkId == bookmark.bookmarkId }) {
                                                                bookmarks[to] += moved
                                                            }
                                                                
                                                            vm.bookmarksState = .data(bookmarks)
                                                        }
                                                    }
                                                    .store(in: &subscriptions)

                                                return true
                                            }

                                            return false
                                        }
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button {
                                            account
                                                .deleteBookmarksCategory(id: bookmark.bookmarkId)
                                                .receive(on: DispatchQueue.main)
                                                .sink { completion in
                                                    guard case let .failure(error) = completion else { return }

                                                    self.error = error
                                                    self.isErrorPresented = true
                                                } receiveValue: { delete in
                                                    if delete {
                                                        bookmarks.removeAll(where: {
                                                            $0.bookmarkId == bookmark.bookmarkId
                                                        })
                                                        
                                                        withAnimation(.easeInOut) {
                                                            vm.bookmarksState = .data(bookmarks)
                                                        }

                                                        if selectedBookmark == bookmark.bookmarkId {
                                                            selectedBookmark = -1
                                                            vm.bookmarkState = .data([])
                                                        }
                                                    }
                                                }
                                                .store(in: &subscriptions)
                                        } label: {
                                            Image(systemName: "trash")
                                                .font(.system(size: 15))
                                        }
                                        .tint(.accentColor)
                                        
                                        Button {
                                            renameBookmark = bookmark
                                        } label: {
                                            Image(systemName: "pencil")
                                                .font(.system(size: 15))
                                        }
                                        .tint(.secondary)
                                    }
                            }
                            .onMove { indexSet, index in
                                if var bookmarks = vm.bookmarksState.data {
                                    var newOrder = bookmarks.map(\.self)
                                    newOrder.move(fromOffsets: indexSet, toOffset: index)
                                    
                                    if newOrder != bookmarks {
                                        account
                                            .reorderBookmarksCategories(newOrder: newOrder)
                                            .receive(on: DispatchQueue.main)
                                            .sink { completion in
                                                guard case let .failure(error) = completion else { return }
                                                
                                                self.error = error
                                                self.isErrorPresented = true
                                            } receiveValue: { reorder in
                                                if reorder {
                                                    bookmarks.move(fromOffsets: indexSet, toOffset: index)

                                                    withAnimation(.easeInOut) {
                                                        vm.bookmarksState = .data(bookmarks)
                                                    }
                                                }
                                            }
                                            .store(in: &subscriptions)
                                    }
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .environment(\.defaultMinListRowHeight, 0)
                        .padding(.top, 52)
                        .scrollClipDisabled()
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
                .background(.windowBackground)
                .padding(.top, 52)
            
            if let error = vm.bookmarkState.error {
                VStack(alignment: .center, spacing: 8) {
                    Text(error.localizedDescription)
                        .font(.system(size: 20, weight: .medium))
                        .lineLimit(nil)
                        .multilineTextAlignment(.center)
                            
                    Button {
                        vm.reloadBookmark(id: selectedBookmark, filter: filter, genre: selectedGenre)
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
            } else if var movies = vm.bookmarkState.data {
                if movies.isEmpty {
                    VStack(alignment: .center, spacing: 8) {
                        Text(selectedBookmark == -1 ? String(localized: "key.bookmarks.select") : String(localized: "key.bookmarks.empty"))
                            .font(.system(size: 20, weight: .medium))
                            .lineLimit(nil)
                            .multilineTextAlignment(.center)
                   
                        if selectedBookmark != -1 {
                            Button {
                                vm.reloadBookmark(id: selectedBookmark, filter: filter, genre: selectedGenre)
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
                                                    account
                                                        .removeFromBookmarks(movies: [movieId], bookmarkUserCategory: selectedBookmark)
                                                        .receive(on: DispatchQueue.main)
                                                        .sink { completion in
                                                            guard case let .failure(error) = completion else { return }
                                                                
                                                            self.error = error
                                                            self.isErrorPresented = true
                                                        } receiveValue: { delete in
                                                            if delete {
                                                                movies.removeAll(where: {
                                                                    $0.id == movie.id
                                                                })
                                                                
                                                                withAnimation(.easeInOut) {
                                                                    vm.bookmarkState = .data(movies)
                                                          
                                                                    if var bookmarks = vm.bookmarksState.data, let index = bookmarks.firstIndex(where: { $0.bookmarkId == selectedBookmark }) {
                                                                        bookmarks[index] -= 1

                                                                        vm.bookmarksState = .data(bookmarks)
                                                                    }
                                                                }
                                                            }
                                                        }
                                                        .store(in: &subscriptions)
                                                }
                                            } label: {
                                                Text("key.delete")
                                            }
                                            .disabled(movie.movieId.id == nil)
                                        }
                                        .task {
                                            if movies.last == movie, vm.paginationState == .idle {
                                                vm.nextPage(id: selectedBookmark, filter: filter, genre: selectedGenre)
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
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .padding(.vertical, 10)
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
                if !(vm.bookmarkState.data?.isEmpty ?? true) || selectedBookmark == -1 {
                    Button {
                        selectedBookmark = -1
                        vm.reloadBookmarks()
                    } label: {
                        Image(systemName: "arrow.trianglehead.clockwise")
                    }
                    .buttonStyle(NavbarButtonStyle(width: 30, height: 22))
                    .keyboardShortcut("r", modifiers: .command)
                }
                
                Button {
                    isCreateBookmarkPresented = true
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(NavbarButtonStyle(width: 22, height: 22))
                .keyboardShortcut("n", modifiers: .command)
            }
        }, toolbar: {
            if vm.bookmarkState != .loading, selectedBookmark != -1 {
                Image(systemName: "line.3.horizontal.decrease.circle")

                Picker("key.filter.select", selection: $filter) {
                    ForEach(BookmarkFilters.allCases) { f in
                        Text(f.rawValue).tag(f)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .buttonStyle(.accessoryBar)
                .controlSize(.large)
                .background(.tertiary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .contentShape(RoundedRectangle(cornerRadius: 6))
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.tertiary.opacity(0.2), lineWidth: 1)
                }
                    
                Divider()
                    .padding(.vertical, 18)

                Picker("key.genre.select", selection: $selectedGenre) {
                    ForEach(Genres.allCases) { g in
                        Text(g.rawValue).tag(g)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .buttonStyle(.accessoryBar)
                .controlSize(.large)
                .background(.tertiary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .contentShape(RoundedRectangle(cornerRadius: 6))
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.tertiary.opacity(0.2), lineWidth: 1)
                }
            }
        })
        .onChange(of: selectedBookmark) {
            if selectedBookmark != -1 {
                vm.reloadBookmark(id: selectedBookmark, filter: filter, genre: selectedGenre)
            }
        }
        .onChange(of: isCreateBookmarkPresented) {
            if !isCreateBookmarkPresented {
                selectedBookmark = -1
                vm.reloadBookmarks()
            }
        }
        .onChange(of: renameBookmark) {
            if renameBookmark == nil {
                selectedBookmark = -1
                vm.reloadBookmarks()
            }
        }
        .onChange(of: filter) {
            vm.reloadBookmark(id: selectedBookmark, filter: filter, genre: selectedGenre)
        }
        .onChange(of: selectedGenre) {
            vm.reloadBookmark(id: selectedBookmark, filter: filter, genre: selectedGenre)
        }
        .load(isLoggedIn) {
            switch vm.bookmarksState {
            case .data:
                break
            default:
                vm.reloadBookmarks()
            }
        }
        .alert("key.ops", isPresented: $isErrorPresented) {
            Button("key.ok", role: .cancel) {}
        } message: {
            if let error {
                Text(error.localizedDescription)
            }
        }
        .dialogSeverity(.critical)
        .sheet(item: $renameBookmark) { bookmark in
            RenameBookmarkSheetView(bookmark: bookmark)
        }
        .sheet(isPresented: $isCreateBookmarkPresented) {
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
