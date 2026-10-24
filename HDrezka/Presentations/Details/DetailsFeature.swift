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

    private enum CancelID { case load, rate }

    @Dependency(\.getMovieDetailsUseCase) private var getMovieDetailsUseCase
    @Dependency(\.getMovieTrailerIdUseCase) private var getMovieTrailerIdUseCase
    @Dependency(\.rateUseCase) private var rateUseCase

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
                if state.details.data == nil {
                    state.details = .loading
                }

                return .run { [id = state.id] send in
                    let result = await Result { try await getMovieDetailsUseCase(movieId: id) }

                    guard case let .success(details) = result, let movieId = details.movieId.id else {
                        await send(.detailsLoaded(result), animation: .easeInOut)

                        return
                    }

                    async let trailerId = getMovieTrailerIdUseCase(movieId: movieId)

                    await send(.detailsLoaded(result), awaitingAnimation: .easeInOut)

                    if let trailerId = try? await trailerId {
                        await send(.trailerLoaded(trailerId), animation: .easeInOut)
                    }
                }
                .cancellable(id: CancelID.load, cancelInFlight: true)

            case let .detailsLoaded(.success(details)):
                state.details = .data(details)

                return .none

            case let .detailsLoaded(.failure(error)):
                if state.details.data != nil {
                    state.alert = .error(error)
                } else {
                    state.details = .error(error)
                }

                return .none

            case let .trailerLoaded(trailerId):
                state.trailerId = trailerId

                return .none

            case let .rate(rating):
                guard let id = state.id.id else { return .none }

                return .run { send in
                    let result = await Result { try await rateUseCase(id: id, rating: rating) }

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
                state.destination = .watch(MovieSelectionFeature.State(id: state.details.data?.movieId ?? state.id))

                return .none

            case .downloadTapped:
                state.destination = .download(MovieSelectionFeature.State(id: state.details.data?.movieId ?? state.id))

                return .none

            case .openExternalPlayerTapped:
                state.destination = .openExternalPlayer(MovieSelectionFeature.State(id: state.details.data?.movieId ?? state.id))

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
