import ComposableArchitecture
import SQLiteData
import SwiftUI

@Reducer
struct WatchingLaterFeature {
    @ObservableState
    struct State: Equatable {
        var movies: DataState<[MovieWatchLater]> = .idle

        @Presents var alert: AlertState<Action.Alert>?
    }

    enum Action {
        case onAppear
        case reload
        case moviesLoaded(Result<[MovieWatchLater], any Error>)
        case switchWatched(MovieWatchLater)
        case watchedSwitched(MovieWatchLater, Result<Void, any Error>)
        case remove(MovieWatchLater)
        case removed(MovieWatchLater, Result<Void, any Error>)
        case alert(PresentationAction<Alert>)

        enum Alert: Equatable {}
    }

    private enum CancelID { case load }

    @Dependency(\.getWatchingLaterMoviesUseCase) private var getWatchingLaterMoviesUseCase
    @Dependency(\.switchWatchedItemUseCase) private var switchWatchedItemUseCase
    @Dependency(\.removeWatchingItemUseCase) private var removeWatchingItemUseCase
    @Dependency(\.defaultDatabase) private var database

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.movies.needsLoad else { return .none }

                return .send(.reload)

            case .reload:
                state.movies = .loading

                return .run { send in
                    let result = await Result { try await getWatchingLaterMoviesUseCase() }

                    await send(.moviesLoaded(result), animation: .easeInOut)
                }
                .cancellable(id: CancelID.load, cancelInFlight: true)

            case let .moviesLoaded(.success(movies)):
                state.movies = .data(movies)

                return .none

            case let .moviesLoaded(.failure(error)):
                state.movies = .error(error)

                return .none

            case let .switchWatched(movie):
                return .run { send in
                    let result = await Result { try await switchWatchedItemUseCase(item: movie) }

                    await send(.watchedSwitched(movie, result), animation: .easeInOut)
                }

            case let .watchedSwitched(movie, .success):
                guard var movies = state.movies.data, let index = movies.firstIndex(of: movie) else { return .none }

                movies[index].watched.toggle()

                if !movie.watched {
                    movies.move(fromOffsets: IndexSet(integer: index), toOffset: movies.count)
                }

                state.movies = .data(movies)

                return .none

            case let .remove(movie):
                return .run { send in
                    let result = await Result { try await removeWatchingItemUseCase(item: movie) }

                    await send(.removed(movie, result), animation: .easeInOut)
                }

            case let .removed(movie, .success):
                if var movies = state.movies.data {
                    movies.removeAll(where: { $0.id == movie.id })
                    state.movies = .data(movies)
                }

                guard let watchLaterId = movie.watchLaterId.id else { return .none }

                return .run { _ in
                    try? await database.write { db in
                        try PlayerPosition
                            .where { $0.id.id.eq(watchLaterId) }
                            .delete()
                            .execute(db)
                    }
                }

            case let .watchedSwitched(_, .failure(error)), let .removed(_, .failure(error)):
                state.alert = .error(error)

                return .none

            case .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
