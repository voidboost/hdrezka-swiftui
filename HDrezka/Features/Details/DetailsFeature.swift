import ComposableArchitecture
import SwiftUI

@Reducer
struct DetailsFeature {
    @Reducer
    enum Destination {
        case bookmarks(BookmarksSheetFeature)
        case createBookmark(CreateBookmarkFeature)
        case watch(MovieSelectionFeature)
        case download(MovieSelectionFeature)
        case openExternalPlayer(MovieSelectionFeature)
    }

    @ObservableState
    struct State: Equatable {
        let id: String
        let title: String?

        var details: DataState<MovieDetailed> = .idle
        var trailerId: String?

        @Presents var alert: AlertState<Action.Alert>?
        @Presents var destination: Destination.State?

        init(movie: MovieSimple) {
            id = movie.movieId
            title = movie.name
        }

        var movieId: String {
            details.data?.movieId ?? id
        }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case reload
        case detailsLoaded(Result<MovieDetailed, any Error>)
        case trailerLoaded(String)
        case rate(Int)
        case rated(Result<(Float?, String?)?, any Error>)
        case bookmarksTapped
        case watchTapped
        case downloadTapped
        case openExternalPlayerTapped
        case push(Destinations)
        case delegate(Delegate)
        case alert(PresentationAction<Alert>)
        case destination(PresentationAction<Destination.Action>)

        enum Alert: Equatable {}

        enum Delegate {
            case push(Destinations)
        }
    }

    private enum CancelID { case load, trailer, rate }

    @Dependency(\.movieDetailsClient) private var movieDetailsClient

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .onAppear:
                guard state.details.needsLoad else { return .none }

                return .send(.reload)

            case .reload:
                state.details = .loading

                return .run { [id = state.id] send in
                    let result = await Result { try await movieDetailsClient.getMovieDetails(movieId: id) }

                    await send(.detailsLoaded(result), animation: .easeInOut)
                }
                .cancellable(id: CancelID.load, cancelInFlight: true)

            case let .detailsLoaded(.success(details)):
                state.details = .data(details)

                guard state.trailerId == nil, let movieId = details.movieId.id else { return .none }

                return .run { send in
                    guard let trailerId = try? await movieDetailsClient.getMovieTrailerId(movieId: movieId) else { return }

                    await send(.trailerLoaded(trailerId), animation: .easeInOut)
                }
                .cancellable(id: CancelID.trailer, cancelInFlight: true)

            case let .detailsLoaded(.failure(error)):
                state.details = .error(error)

                return .none

            case let .trailerLoaded(trailerId):
                state.trailerId = trailerId

                return .none

            case let .rate(rating):
                guard let id = state.id.id else { return .none }

                return .run { send in
                    let result = await Result { try await movieDetailsClient.rate(id: id, rating: rating) }

                    await send(.rated(result), animation: .easeInOut)
                }
                .cancellable(id: CancelID.rate, cancelInFlight: true)

            case let .rated(.success(rating)):
                guard let rating, case var .data(details) = state.details else {
                    state.alert = .error()

                    return .none
                }

                details.rate(rating.0, rating.1)
                state.details = .data(details)

                return .none

            case let .rated(.failure(error)):
                state.alert = .error(error)

                return .none

            case .bookmarksTapped:
                state.destination = .bookmarks(BookmarksSheetFeature.State(id: state.id))

                return .none

            case .watchTapped:
                state.destination = .watch(MovieSelectionFeature.State(id: state.movieId))

                return .none

            case .downloadTapped:
                state.destination = .download(MovieSelectionFeature.State(id: state.movieId))

                return .none

            case .openExternalPlayerTapped:
                state.destination = .openExternalPlayer(MovieSelectionFeature.State(id: state.movieId))

                return .none

            case .destination(.presented(.bookmarks(.delegate(.createBookmark)))):
                state.destination = .createBookmark(CreateBookmarkFeature.State())

                return .none

            case .destination(.dismiss):
                if case .createBookmark = state.destination {
                    state.destination = .bookmarks(BookmarksSheetFeature.State(id: state.id))
                }

                return .none

            case let .push(route):
                return .send(.delegate(.push(route)))

            case .alert, .destination, .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$destination, action: \.destination)
    }
}

extension DetailsFeature.Destination.State: Equatable {}
