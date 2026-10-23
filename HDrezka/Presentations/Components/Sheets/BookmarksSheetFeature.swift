import ComposableArchitecture
import SwiftUI

@Reducer
struct BookmarksSheetFeature {
    @ObservableState
    struct State: Equatable {
        let id: String

        var bookmarks: DataState<[Bookmark]> = .loading

        @Presents var alert: AlertState<Action.Alert>?
    }

    enum Action {
        case onAppear
        case reload
        case bookmarksLoaded(Result<[Bookmark], any Error>)
        case toggle(Bookmark)
        case toggled(Bookmark, isAdded: Bool, Result<Bool, any Error>)
        case createTapped
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        enum Alert: Equatable {
            case dismiss
        }

        enum Delegate {
            case createBookmark
        }
    }

    private enum CancelID { case load }

    @Dependency(\.addToBookmarksUseCase) private var addToBookmarksUseCase
    @Dependency(\.removeFromBookmarksUseCase) private var removeFromBookmarksUseCase
    @Dependency(\.getMovieBookmarksUseCase) private var getMovieBookmarksUseCase
    @Dependency(\.dismiss) private var dismiss

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return load(id: state.id)

            case .reload:
                state.bookmarks = .loading

                return load(id: state.id)

            case let .bookmarksLoaded(.success(bookmarks)):
                state.bookmarks = .data(bookmarks)

                return .none

            case let .bookmarksLoaded(.failure(error)):
                state.bookmarks = .error(error)

                return .none

            case let .toggle(bookmark):
                guard let movieId = state.id.id else { return .none }

                let isChecked = bookmark.isChecked ?? false

                return .run { send in
                    let result = await Result {
                        if isChecked {
                            try await removeFromBookmarksUseCase(movies: [movieId], bookmarkUserCategory: bookmark.bookmarkId)
                        } else {
                            try await addToBookmarksUseCase(movieId: movieId, bookmarkUserCategory: bookmark.bookmarkId)
                        }
                    }

                    await send(.toggled(bookmark, isAdded: !isChecked, result), animation: .easeInOut)
                }

            case let .toggled(bookmark, isAdded, .success(success)):
                guard success, var bookmarks = state.bookmarks.data, let index = bookmarks.firstIndex(where: { $0.bookmarkId == bookmark.bookmarkId }) else { return .none }

                if isAdded {
                    bookmarks[index] += 1
                } else {
                    bookmarks[index] -= 1
                }

                state.bookmarks = .data(bookmarks)

                return .none

            case let .toggled(_, _, .failure(error)):
                state.alert = AlertState(
                    title: { TextState("key.ops") },
                    actions: { ButtonState(role: .cancel, action: .dismiss) { TextState("key.ok") } },
                    message: { TextState(error.localizedDescription) }
                )

                return .none

            case .createTapped:
                return .send(.delegate(.createBookmark))

            case .alert(.presented(.dismiss)):
                return .run { _ in await dismiss() }

            case .alert, .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }

    private func load(id: String) -> Effect<Action> {
        .run { send in
            let result = await Result { try await getMovieBookmarksUseCase(movieId: id) }

            await send(.bookmarksLoaded(result), animation: .easeInOut)
        }
        .cancellable(id: CancelID.load, cancelInFlight: true)
    }
}
