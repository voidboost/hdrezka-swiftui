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

    func getBookmarks() {
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

    private func getBookmark(id: Int, filter: BookmarkFilters, genre: Genres, isInitial: Bool = true) {
        getPublisher(id: id, filter: filter, genre: genre)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                guard case let .failure(error) = completion else { return }

                withAnimation(.easeInOut) {
                    if isInitial {
                        self.bookmarkState = .error(error as NSError)
                    } else {
                        self.paginationState = .error(error as NSError)
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
                            self.paginationState = .error(NSError())
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

    func load(id: Int, filter: BookmarkFilters, genre: Genres) {
        bookmarkState = .loading
        paginationState = .idle
        page = 1

        getBookmark(id: id, filter: filter, genre: genre)
    }

    func loadMore(id: Int, filter: BookmarkFilters, genre: Genres) {
        guard paginationState == .idle else { return }

        withAnimation(.easeInOut) {
            paginationState = .loading
        }

        getBookmark(id: id, filter: filter, genre: genre, isInitial: false)
    }
}
