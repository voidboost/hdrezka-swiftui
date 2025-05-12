import Combine
import Factory
import SwiftUI

@Observable
class BookmarksViewModel {
    @ObservationIgnored
    @Injected(\.account)
    private var account

    @ObservationIgnored
    private var subscriptions: Set<AnyCancellable> = []

    var bookmarksState: DataState<[Bookmark]> = .loading

    private func getBookmarks() {
        bookmarksState = .loading

        bookmarkState = .data([])
        paginationState = .loading
        page = 1

        account
            .getBookmarks()
            .receive(on: DispatchQueue.main)
            .sink { completion in
                guard case let .failure(error) = completion else { return }

                withAnimation(.easeInOut) {
                    self.bookmarksState = .error(error as NSError)
                }
            } receiveValue: { result in
                withAnimation(.easeInOut) {
                    self.bookmarksState = .data(result)
                }
            }
            .store(in: &subscriptions)
    }

    var bookmarkState: DataState<[MovieSimple]> = .data([])
    var paginationState: DataPaginationState = .loading

    @ObservationIgnored
    private var page = 1

    private func getBookmark(id: Int, filter: BookmarkFilters, genre: Genres) {
        bookmarkState = .loading
        paginationState = .idle
        page = 1

        let publisher = switch filter {
        case .added:
            account.getBookmarksByCategoryAdded(id: id, genre: genre.genreCode, page: page)
        case .year:
            account.getBookmarksByCategoryYear(id: id, genre: genre.genreCode, page: page)
        case .popular:
            account.getBookmarksByCategoryPopular(id: id, genre: genre.genreCode, page: page)
        }

        publisher
            .receive(on: DispatchQueue.main)
            .sink { completion in
                guard case let .failure(error) = completion else { return }

                withAnimation(.easeInOut) {
                    self.bookmarkState = .error(error as NSError)
                }
            } receiveValue: { result in
                self.page += 1

                withAnimation(.easeInOut) {
                    self.bookmarkState = .data(result)
                }
            }
            .store(in: &subscriptions)
    }

    func nextPage(id: Int, filter: BookmarkFilters, genre: Genres) {
        guard paginationState == .idle else {
            return
        }

        withAnimation(.easeInOut) {
            paginationState = .loading
        }

        let publisher = switch filter {
        case .added:
            account.getBookmarksByCategoryAdded(id: id, genre: genre.genreCode, page: page)
        case .year:
            account.getBookmarksByCategoryYear(id: id, genre: genre.genreCode, page: page)
        case .popular:
            account.getBookmarksByCategoryPopular(id: id, genre: genre.genreCode, page: page)
        }

        publisher
            .receive(on: DispatchQueue.main)
            .sink { completion in
                guard case let .failure(error) = completion else { return }

                withAnimation(.easeInOut) {
                    self.paginationState = .error(error as NSError)
                }
            } receiveValue: { result in
                if !result.isEmpty {
                    withAnimation(.easeInOut) {
                        self.bookmarkState.append(result)
                        self.paginationState = .idle
                    }
                    self.page += 1
                } else {
                    withAnimation(.easeInOut) {
                        self.paginationState = .error(NSError())
                    }
                }
            }
            .store(in: &subscriptions)
    }

    func reloadBookmarks() {
        getBookmarks()
    }

    func reloadBookmark(id: Int, filter: BookmarkFilters, genre: Genres) {
        getBookmark(id: id, filter: filter, genre: genre)
    }
}
