import Combine
import FactoryKit
import SwiftUI

@Observable
class BookmarksViewModel {
    @ObservationIgnored @LazyInjected(\.getBookmarksUseCase) private var getBookmarksUseCase
    @ObservationIgnored @LazyInjected(\.getBookmarksByCategoryAddedUseCase) private var getBookmarksByCategoryAddedUseCase
    @ObservationIgnored @LazyInjected(\.getBookmarksByCategoryPopularUseCase) private var getBookmarksByCategoryPopularUseCase
    @ObservationIgnored @LazyInjected(\.getBookmarksByCategoryYearUseCase) private var getBookmarksByCategoryYearUseCase
    @ObservationIgnored @LazyInjected(\.deleteBookmarksCategoryUseCase) private var deleteBookmarksCategoryUseCase
    @ObservationIgnored @LazyInjected(\.moveBetweenBookmarksUseCase) private var moveBetweenBookmarksUseCase
    @ObservationIgnored @LazyInjected(\.reorderBookmarksCategoriesUseCase) private var reorderBookmarksCategoriesUseCase
    @ObservationIgnored @LazyInjected(\.removeFromBookmarksUseCase) private var removeFromBookmarksUseCase

    @ObservationIgnored private var subscriptions: Set<AnyCancellable> = []

    private(set) var bookmarksState: DataState<[Bookmark]> = .loading
    private(set) var bookmarkState: DataState<[MovieSimple]> = .data([])
    private(set) var paginationState: DataPaginationState = .loading

    var selectedBookmark: Int = -1

    private(set) var error: Error?
    var isErrorPresented: Bool = false

    var renameBookmark: Bookmark?
    var isCreateBookmarkPresented: Bool = false

    var genre = Genres.all
    var filter = BookmarkFilters.added

    func getBookmarks(reset: Bool = false) {
        if reset {
            selectedBookmark = -1
        }

        bookmarksState = .loading

        bookmarkState = .data([])
        paginationState = .loading
        page = 1

        getBookmarksUseCase()
            .receive(on: DispatchQueue.main)
            .sink { completion in
                guard case let .failure(error) = completion else { return }

                withAnimation(.easeInOut) {
                    self.bookmarksState = .error(error)
                }
            } receiveValue: { result in
                withAnimation(.easeInOut) {
                    self.bookmarksState = .data(result)
                }
            }
            .store(in: &subscriptions)
    }

    @ObservationIgnored private var page = 1

    private func getBookmark(isInitial: Bool = true) {
        getPublisher(id: selectedBookmark, filter: filter, genre: genre)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                guard case let .failure(error) = completion else { return }

                withAnimation(.easeInOut) {
                    if isInitial {
                        self.bookmarkState = .error(error)
                    } else {
                        self.paginationState = .error(error)
                    }
                }
            } receiveValue: { result in
                self.page += 1

                withAnimation(.easeInOut) {
                    if isInitial {
                        self.bookmarkState = .data(result)
                    } else {
                        if !result.isEmpty {
                            self.bookmarkState.append(result)
                            self.paginationState = .idle
                        } else {
                            self.paginationState = .error(HDrezkaError.unknown)
                        }
                    }
                }
            }
            .store(in: &subscriptions)
    }

    private func getPublisher(id: Int, filter: BookmarkFilters, genre: Genres) -> AnyPublisher<[MovieSimple], Error> {
        switch filter {
        case .added:
            getBookmarksByCategoryAddedUseCase(id: id, genre: genre.genreCode, page: page)
        case .year:
            getBookmarksByCategoryYearUseCase(id: id, genre: genre.genreCode, page: page)
        case .popular:
            getBookmarksByCategoryPopularUseCase(id: id, genre: genre.genreCode, page: page)
        }
    }

    func load() {
        bookmarkState = .loading
        paginationState = .idle
        page = 1

        getBookmark()
    }

    func loadMore() {
        guard paginationState == .idle else { return }

        withAnimation(.easeInOut) {
            paginationState = .loading
        }

        getBookmark(isInitial: false)
    }

    func deleteBookmarksCategory(bookmark: Bookmark) {
        deleteBookmarksCategoryUseCase(id: bookmark.bookmarkId)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                guard case let .failure(error) = completion else { return }

                self.error = error
                self.isErrorPresented = true
            } receiveValue: { delete in
                if delete, var bookmarks = self.bookmarksState.data {
                    bookmarks.removeAll(where: {
                        $0.bookmarkId == bookmark.bookmarkId
                    })

                    withAnimation(.easeInOut) {
                        self.bookmarksState = .data(bookmarks)
                    }

                    if self.selectedBookmark == bookmark.bookmarkId {
                        self.selectedBookmark = -1
                        self.bookmarkState = .data([])
                    }
                }
            }
            .store(in: &subscriptions)
    }

    func moveBetweenBookmarks(movies: [MovieSimple], bookmark: Bookmark) {
        moveBetweenBookmarksUseCase(movies: movies.compactMap(\.movieId.id), fromBookmarkUserCategory: selectedBookmark, toBookmarkUserCategory: bookmark.bookmarkId)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                guard case let .failure(error) = completion else { return }

                self.error = error
                self.isErrorPresented = true
            } receiveValue: { moved in
                withAnimation(.easeInOut) {
                    if var data = self.bookmarkState.data {
                        data.removeAll(where: { movie in
                            movies.contains(where: { movedMovie in
                                movie.movieId == movedMovie.movieId
                            })
                        })

                        self.bookmarkState = .data(data)
                    }

                    if var bookmarks = self.bookmarksState.data {
                        if let from = bookmarks.firstIndex(where: { $0.bookmarkId == self.selectedBookmark }) {
                            bookmarks[from] -= 1
                        }

                        if let to = bookmarks.firstIndex(where: { $0.bookmarkId == bookmark.bookmarkId }) {
                            bookmarks[to] += moved
                        }

                        self.bookmarksState = .data(bookmarks)
                    }
                }
            }
            .store(in: &subscriptions)
    }

    func reorderBookmarksCategories(fromOffsets: IndexSet, toOffset: Int) {
        if var bookmarks = bookmarksState.data {
            var newOrder = bookmarks.map(\.self)
            newOrder.move(fromOffsets: fromOffsets, toOffset: toOffset)

            if newOrder != bookmarks {
                reorderBookmarksCategoriesUseCase(newOrder: newOrder)
                    .receive(on: DispatchQueue.main)
                    .sink { completion in
                        guard case let .failure(error) = completion else { return }

                        self.error = error
                        self.isErrorPresented = true
                    } receiveValue: { reorder in
                        if reorder {
                            bookmarks.move(fromOffsets: fromOffsets, toOffset: toOffset)

                            withAnimation(.easeInOut) {
                                self.bookmarksState = .data(bookmarks)
                            }
                        }
                    }
                    .store(in: &subscriptions)
            }
        }
    }

    func removeFromBookmarks(movies ids: [String]) {
        removeFromBookmarksUseCase(movies: ids, bookmarkUserCategory: selectedBookmark)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                guard case let .failure(error) = completion else { return }

                self.error = error
                self.isErrorPresented = true
            } receiveValue: { delete in
                if delete, var movies = self.bookmarkState.data {
                    movies.removeAll(where: {
                        if let movieId = $0.movieId.id {
                            ids.contains(movieId)
                        } else {
                            false
                        }
                    })

                    withAnimation(.easeInOut) {
                        self.bookmarkState = .data(movies)

                        if var bookmarks = self.bookmarksState.data, let index = bookmarks.firstIndex(where: { $0.bookmarkId == self.selectedBookmark }) {
                            bookmarks[index] -= 1

                            self.bookmarksState = .data(bookmarks)
                        }
                    }
                }
            }
            .store(in: &subscriptions)
    }
}
