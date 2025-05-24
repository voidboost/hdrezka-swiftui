import Combine
import FactoryKit
import SwiftUI

class BookmarksViewModel: ObservableObject {
    @Injected(\.getBookmarksUseCase) private var getBookmarksUseCase
    @Injected(\.getBookmarksByCategoryAddedUseCase) private var getBookmarksByCategoryAddedUseCase
    @Injected(\.getBookmarksByCategoryPopularUseCase) private var getBookmarksByCategoryPopularUseCase
    @Injected(\.getBookmarksByCategoryYearUseCase) private var getBookmarksByCategoryYearUseCase

    private var subscriptions: Set<AnyCancellable> = []

    @Published var bookmarksState: DataState<[Bookmark]> = .loading

    private func getBookmarks() {
        bookmarksState = .loading

        bookmarkState = .data([])
        paginationState = .loading
        page = 1

        getBookmarksUseCase()
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

    @Published var bookmarkState: DataState<[MovieSimple]> = .data([])
    @Published var paginationState: DataPaginationState = .loading

    private var page = 1

    private func getBookmark(id: Int, filter: BookmarkFilters, genre: Genres) {
        bookmarkState = .loading
        paginationState = .idle
        page = 1

        let publisher = switch filter {
        case .added:
            getBookmarksByCategoryAddedUseCase(id: id, genre: genre.genreCode, page: page)
        case .year:
            getBookmarksByCategoryYearUseCase(id: id, genre: genre.genreCode, page: page)
        case .popular:
            getBookmarksByCategoryPopularUseCase(id: id, genre: genre.genreCode, page: page)
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
            getBookmarksByCategoryAddedUseCase(id: id, genre: genre.genreCode, page: page)
        case .year:
            getBookmarksByCategoryYearUseCase(id: id, genre: genre.genreCode, page: page)
        case .popular:
            getBookmarksByCategoryPopularUseCase(id: id, genre: genre.genreCode, page: page)
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
