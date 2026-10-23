import ComposableArchitecture
import SwiftUI

@Reducer
struct SeriesUpdatesFeature {
    @ObservableState
    struct State: Equatable {
        var seriesUpdates: DataState<[SeriesUpdateGroup]> = .loading
    }

    enum Action {
        case reload
        case seriesUpdatesLoaded(Result<[SeriesUpdateGroup], any Error>)
        case movieTapped(MovieSimple)
        case delegate(Delegate)

        enum Delegate {
            case openMovie(MovieSimple)
        }
    }

    private enum CancelID { case load }

    @Dependency(\.getSeriesUpdatesUseCase) private var getSeriesUpdatesUseCase
    @Dependency(\.dismiss) private var dismiss

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .reload:
                state.seriesUpdates = .loading

                return .run { send in
                    let result = await Result { try await getSeriesUpdatesUseCase() }

                    await send(.seriesUpdatesLoaded(result), animation: .easeInOut)
                }
                .cancellable(id: CancelID.load, cancelInFlight: true)

            case let .seriesUpdatesLoaded(.success(seriesUpdates)):
                state.seriesUpdates = .data(seriesUpdates)

                return .none

            case let .seriesUpdatesLoaded(.failure(error)):
                state.seriesUpdates = .error(error)

                return .none

            case let .movieTapped(movie):
                return .run { send in
                    await send(.delegate(.openMovie(movie)))
                    await dismiss()
                }

            case .delegate:
                return .none
            }
        }
    }
}
