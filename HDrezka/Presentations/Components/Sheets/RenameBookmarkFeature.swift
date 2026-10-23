import ComposableArchitecture
import SwiftUI

@Reducer
struct RenameBookmarkFeature {
    @ObservableState
    struct State: Equatable {
        let bookmark: Bookmark

        var name: String
        var status: EmptyState = .data

        init(bookmark: Bookmark) {
            self.bookmark = bookmark
            name = bookmark.name
        }

        var canSubmit: Bool {
            !name.trim().isEmpty && name.trim() != bookmark.name
        }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case submit
        case cancelRequest
        case retry
        case renamed(Result<Bool, any Error>)
    }

    private enum CancelID { case request }

    @Dependency(\.changeBookmarksCategoryNameUseCase) private var changeBookmarksCategoryNameUseCase
    @Dependency(\.dismiss) private var dismiss

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .submit:
                guard state.canSubmit else { return .none }

                state.status = .loading

                return .run { [id = state.bookmark.bookmarkId, name = state.name.trim()] send in
                    let result = await Result { try await changeBookmarksCategoryNameUseCase(id: id, newName: name) }

                    await send(.renamed(result), animation: .easeInOut)
                }
                .cancellable(id: CancelID.request)

            case .cancelRequest, .retry:
                state.status = .data

                return .cancel(id: CancelID.request)

            case .renamed(.success(true)):
                return .run { _ in await dismiss() }

            case .renamed(.success(false)):
                state.status = .error(HDrezkaError.unknown)

                return .none

            case let .renamed(.failure(error)):
                state.status = .error(error)

                return .none
            }
        }
    }
}
