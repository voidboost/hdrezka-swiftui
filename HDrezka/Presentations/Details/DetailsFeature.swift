import ComposableArchitecture
import SwiftUI

@Reducer
struct DetailsFeature {
    @ObservableState
    struct State: Equatable {
        let id: String

        var details: DataState<MovieDetailed> = .loading
        var trailerId: String?

        var countryDestination: MovieCountry?
        var genreDestination: MovieGenre?
        var personDestination: PersonSimple?
        var listDestination: MovieList?
        var collectionDestination: MoviesCollection?

        @Presents var alert: AlertState<Action.Alert>?
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case reload
        case detailsLoaded(Result<MovieDetailed, any Error>)
        case trailerLoaded(String)
        case rate(Int)
        case rated(Result<(Float?, String?)?, any Error>)
        case alert(PresentationAction<Alert>)

        enum Alert: Equatable {}
    }

    private enum CancelID { case load }

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
                guard state.details.data == nil else { return .none }

                return .send(.reload)

            case .reload:
                state.details = .loading

                return .run { [id = state.id] send in
                    let result = await Result { try await getMovieDetailsUseCase(movieId: id) }

                    await send(.detailsLoaded(result), animation: .easeInOut)
                }
                .cancellable(id: CancelID.load, cancelInFlight: true)

            case let .detailsLoaded(.success(details)):
                state.details = .data(details)

                guard let movieId = details.movieId.id else { return .none }

                return .run { send in
                    let trailerId = try await getMovieTrailerIdUseCase(movieId: movieId)

                    await send(.trailerLoaded(trailerId), animation: .easeInOut)
                }
                .cancellable(id: CancelID.load)

            case let .detailsLoaded(.failure(error)):
                state.details = .error(error)

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

            case .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
