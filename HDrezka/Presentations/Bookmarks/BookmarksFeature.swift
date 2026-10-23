import ComposableArchitecture
import SwiftUI

@Reducer
struct BookmarksFeature {
    @Reducer
    enum Destination {
        case createBookmark(CreateBookmarkFeature)
        case renameBookmark(RenameBookmarkFeature)
    }

    @ObservableState
    struct State: Equatable {
        fileprivate var hasAppeared = false

        var bookmarks: DataState<[Bookmark]> = .loading
        var movies: DataState<[MovieSimple]> = .data([])
        var paginationState: DataPaginationState = .idle

        var selectedBookmark: Int?

        @Presents var destination: Destination.State?

        var genre = Genres.all
        var filter = BookmarkFilters.added

        @Presents var alert: AlertState<Action.Alert>?

        fileprivate var page = 1
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case createTapped
        case renameTapped(Bookmark)
        case destination(PresentationAction<Destination.Action>)
        case reloadBookmarks(reset: Bool)
        case bookmarksLoaded(Result<[Bookmark], any Error>)
        case reloadMovies
        case loadMore
        case moviesLoaded(isInitial: Bool, Result<[MovieSimple], any Error>)
        case deleteBookmark(Bookmark)
        case bookmarkDeleted(Bookmark, Result<Bool, any Error>)
        case moveMovies([MovieSimple], to: Bookmark)
        case moviesMoved([MovieSimple], from: Int, to: Bookmark, Result<Int, any Error>)
        case reorderBookmarks(fromOffsets: IndexSet, toOffset: Int)
        case bookmarksReordered([Bookmark], Result<Bool, any Error>)
        case removeMovies([String])
        case moviesRemoved([String], from: Int, Result<Bool, any Error>)
        case alert(PresentationAction<Alert>)

        enum Alert: Equatable {}
    }

    private enum CancelID {
        case bookmarks
        case movies
    }

    @Dependency(\.getBookmarksUseCase) private var getBookmarksUseCase
    @Dependency(\.getBookmarksByCategoryAddedUseCase) private var getBookmarksByCategoryAddedUseCase
    @Dependency(\.getBookmarksByCategoryPopularUseCase) private var getBookmarksByCategoryPopularUseCase
    @Dependency(\.getBookmarksByCategoryYearUseCase) private var getBookmarksByCategoryYearUseCase
    @Dependency(\.deleteBookmarksCategoryUseCase) private var deleteBookmarksCategoryUseCase
    @Dependency(\.moveBetweenBookmarksUseCase) private var moveBetweenBookmarksUseCase
    @Dependency(\.reorderBookmarksCategoriesUseCase) private var reorderBookmarksCategoriesUseCase
    @Dependency(\.removeFromBookmarksUseCase) private var removeFromBookmarksUseCase

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding(\.selectedBookmark):
                guard state.selectedBookmark != nil else { return .none }

                return .send(.reloadMovies)

            case .binding(\.filter), .binding(\.genre):
                return .send(.reloadMovies)

            case .binding:
                return .none

            case .createTapped:
                state.destination = .createBookmark(CreateBookmarkFeature.State())

                return .none

            case let .renameTapped(bookmark):
                state.destination = .renameBookmark(RenameBookmarkFeature.State(bookmark: bookmark))

                return .none

            case .destination(.dismiss):
                return .send(.reloadBookmarks(reset: true))

            case .destination:
                return .none

            case .onAppear:
                guard state.bookmarks.data == nil, !state.hasAppeared || state.bookmarks.error != nil else { return .none }

                state.hasAppeared = true

                return .send(.reloadBookmarks(reset: false))

            case let .reloadBookmarks(reset):
                if reset {
                    state.selectedBookmark = nil
                }

                state.bookmarks = .loading
                state.movies = .data([])
                state.paginationState = .idle
                state.page = 1

                return .merge(
                    .cancel(id: CancelID.movies),
                    .run { send in
                        let result = await Result { try await getBookmarksUseCase() }

                        await send(.bookmarksLoaded(result), animation: .easeInOut)
                    }
                    .cancellable(id: CancelID.bookmarks, cancelInFlight: true)
                )

            case let .bookmarksLoaded(.success(bookmarks)):
                state.bookmarks = .data(bookmarks)

                return .none

            case let .bookmarksLoaded(.failure(error)):
                state.bookmarks = .error(error)

                return .none

            case .reloadMovies:
                guard let selectedBookmark = state.selectedBookmark else { return .none }

                state.movies = .loading
                state.paginationState = .idle
                state.page = 1

                return loadMovies(id: selectedBookmark, state: state, isInitial: true)

            case .loadMore:
                guard state.paginationState == .idle, let selectedBookmark = state.selectedBookmark else { return .none }

                state.paginationState = .loading

                return loadMovies(id: selectedBookmark, state: state, isInitial: false)

            case let .moviesLoaded(isInitial, result):
                if case .success = result {
                    state.page += 1
                }

                state.paginationState = state.movies.receivePage(result, isInitial: isInitial, emptyPageIsError: true)

                return .none

            case let .deleteBookmark(bookmark):
                return .run { send in
                    let result = await Result { try await deleteBookmarksCategoryUseCase(id: bookmark.bookmarkId) }

                    await send(.bookmarkDeleted(bookmark, result), animation: .easeInOut)
                }

            case let .bookmarkDeleted(bookmark, .success(deleted)):
                guard deleted, var bookmarks = state.bookmarks.data else { return .none }

                bookmarks.removeAll(where: { $0.bookmarkId == bookmark.bookmarkId })
                state.bookmarks = .data(bookmarks)

                if state.selectedBookmark == bookmark.bookmarkId {
                    state.selectedBookmark = nil
                    state.movies = .data([])

                    return .cancel(id: CancelID.movies)
                }

                return .none

            case let .moveMovies(movies, toBookmark):
                guard let fromBookmark = state.selectedBookmark else { return .none }

                return .run { send in
                    let result = await Result {
                        try await moveBetweenBookmarksUseCase(movies: movies.compactMap(\.movieId.id), fromBookmarkUserCategory: fromBookmark, toBookmarkUserCategory: toBookmark.bookmarkId)
                    }

                    await send(.moviesMoved(movies, from: fromBookmark, to: toBookmark, result), animation: .easeInOut)
                }

            case let .moviesMoved(movies, fromBookmark, toBookmark, .success(moved)):
                if var data = state.movies.data {
                    data.removeAll(where: { movie in
                        movies.contains(where: { movedMovie in
                            movie.movieId == movedMovie.movieId
                        })
                    })

                    state.movies = .data(data)
                }

                if var bookmarks = state.bookmarks.data {
                    if let from = bookmarks.firstIndex(where: { $0.bookmarkId == fromBookmark }) {
                        bookmarks[from] -= 1
                    }

                    if let to = bookmarks.firstIndex(where: { $0.bookmarkId == toBookmark.bookmarkId }) {
                        bookmarks[to] += moved
                    }

                    state.bookmarks = .data(bookmarks)
                }

                return .none

            case let .reorderBookmarks(fromOffsets, toOffset):
                guard let bookmarks = state.bookmarks.data else { return .none }

                var newOrder = bookmarks
                newOrder.move(fromOffsets: fromOffsets, toOffset: toOffset)

                guard newOrder != bookmarks else { return .none }

                return .run { [newOrder] send in
                    let result = await Result { try await reorderBookmarksCategoriesUseCase(newOrder: newOrder) }

                    await send(.bookmarksReordered(newOrder, result), animation: .easeInOut)
                }

            case let .bookmarksReordered(newOrder, .success(reordered)):
                if reordered {
                    state.bookmarks = .data(newOrder)
                }

                return .none

            case let .removeMovies(ids):
                guard let selectedBookmark = state.selectedBookmark else { return .none }

                return .run { send in
                    let result = await Result { try await removeFromBookmarksUseCase(movies: ids, bookmarkUserCategory: selectedBookmark) }

                    await send(.moviesRemoved(ids, from: selectedBookmark, result), animation: .easeInOut)
                }

            case let .moviesRemoved(ids, fromBookmark, .success(removed)):
                guard removed, var movies = state.movies.data else { return .none }

                movies.removeAll(where: {
                    if let movieId = $0.movieId.id {
                        ids.contains(movieId)
                    } else {
                        false
                    }
                })

                state.movies = .data(movies)

                if var bookmarks = state.bookmarks.data, let index = bookmarks.firstIndex(where: { $0.bookmarkId == fromBookmark }) {
                    bookmarks[index] -= 1

                    state.bookmarks = .data(bookmarks)
                }

                return .none

            case let .bookmarkDeleted(_, .failure(error)),
                 let .moviesMoved(_, _, _, .failure(error)),
                 let .bookmarksReordered(_, .failure(error)),
                 let .moviesRemoved(_, _, .failure(error)):
                state.alert = .error(error)

                return .none

            case .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$destination, action: \.destination)
    }

    private func loadMovies(id: Int, state: State, isInitial: Bool) -> Effect<Action> {
        .run { [filter = state.filter, genre = state.genre.genreCode, page = state.page] send in
            let result = await Result {
                switch filter {
                case .added:
                    try await getBookmarksByCategoryAddedUseCase(id: id, genre: genre, page: page)
                case .year:
                    try await getBookmarksByCategoryYearUseCase(id: id, genre: genre, page: page)
                case .popular:
                    try await getBookmarksByCategoryPopularUseCase(id: id, genre: genre, page: page)
                }
            }

            await send(.moviesLoaded(isInitial: isInitial, result), animation: .easeInOut)
        }
        .cancellable(id: CancelID.movies, cancelInFlight: true)
    }
}

extension BookmarksFeature.Destination.State: Equatable {}
