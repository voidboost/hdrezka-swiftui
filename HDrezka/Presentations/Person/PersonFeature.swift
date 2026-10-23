import ComposableArchitecture
import SwiftUI

@Reducer
struct PersonFeature {
    @ObservableState
    struct State: Equatable {
        fileprivate var hasAppeared = false

        let id: String
        let name: String

        var details: DataState<PersonDetailed> = .loading

        init(person: PersonSimple) {
            id = person.personId
            name = person.name
        }
    }

    enum Action {
        case onAppear
        case reload
        case detailsLoaded(Result<PersonDetailed, any Error>)
    }

    private enum CancelID { case load }

    @Dependency(\.getPersonDetailsUseCase) private var getPersonDetailsUseCase

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // onAppear can fire more than once; only an error warrants loading again while there is no data.
                guard state.details.data == nil, !state.hasAppeared || state.details.error != nil else { return .none }

                state.hasAppeared = true

                return .send(.reload)

            case .reload:
                state.details = .loading

                return .run { [id = state.id] send in
                    let result = await Result { try await getPersonDetailsUseCase(id: id) }

                    await send(.detailsLoaded(result), animation: .easeInOut)
                }
                .cancellable(id: CancelID.load, cancelInFlight: true)

            case let .detailsLoaded(.success(details)):
                state.details = .data(details)

                return .none

            case let .detailsLoaded(.failure(error)):
                state.details = .error(error)

                return .none
            }
        }
    }
}
