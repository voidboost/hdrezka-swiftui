import ComposableArchitecture
import SwiftUI

@Reducer
struct CommentReportFeature {
    @ObservableState
    struct State: Equatable {
        let comment: Comment

        var report: Reports?
        var message = ""
        var status: EmptyState = .data

        var canSubmit: Bool {
            (report != nil && report != .other) || (report == .other && !message.trim().isEmpty)
        }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case submit
        case cancelRequest
        case retry
        case reported(Result<Void, any Error>)
    }

    private enum CancelID { case request }

    @Dependency(\.reportCommentUseCase) private var reportCommentUseCase
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

                let issue = switch state.report {
                case .obscene: 1
                case .spoiler: 4
                case .insulting: 2
                case .flood: 3
                case .other, nil: 0
                }

                return .run { [id = state.comment.commentId, text = issue == 0 ? state.message : ""] send in
                    let result = await Result { try await reportCommentUseCase(id: id, issue: issue, text: text) }

                    await send(.reported(result), animation: .easeInOut)
                }
                .cancellable(id: CancelID.request)

            case .cancelRequest, .retry:
                state.status = .data

                return .cancel(id: CancelID.request)

            case .reported(.success):
                return .run { _ in await dismiss() }

            case let .reported(.failure(error)):
                state.status = .error(error)

                return .none
            }
        }
    }
}
