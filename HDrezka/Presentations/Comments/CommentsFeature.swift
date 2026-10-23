import ComposableArchitecture
import SwiftUI

@Reducer
struct CommentsFeature {
    @ObservableState
    struct State: Equatable {
        let id: String
        let adb: String?
        let type: String?

        var comments: DataState<[Comment]> = .loading
        var paginationState: DataPaginationState = .idle

        var reply: String?
        var reportComment: Comment?
        var comment: Comment?
        var isCommentPresented = false
        var likes: [String: Likes] = [:]
        var movieDestination: MovieSimple?

        @Presents var alert: AlertState<Action.Alert>?
        @Presents var moderationAlert: AlertState<Action.Alert>?
        @Presents var deleteDialog: ConfirmationDialogState<Action.DeleteDialog>?

        fileprivate var page = 1

        init(details: MovieDetailed) {
            id = details.movieId
            adb = details.adb
            type = details.type
        }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case reload
        case loadMore
        case commentsLoaded(isInitial: Bool, Result<[Comment], any Error>)
        case linkedCommentTapped(movieId: String, commentId: String)
        case linkedCommentLoaded(Result<Comment, any Error>)
        case likeTapped(Comment)
        case likeToggled(Comment, Result<(Int, Bool), any Error>)
        case likesHovered(Comment)
        case likesLoaded(commentId: String, Result<[Like], any Error>)
        case sendComment(name: String?, text: String)
        case commentSent(Result<SendCommentResult, any Error>)
        case deleteTapped(Comment)
        case commentDeleted(Comment, Result<(Bool, String?), any Error>)
        case alert(PresentationAction<Alert>)
        case moderationAlert(PresentationAction<Alert>)
        case deleteDialog(PresentationAction<DeleteDialog>)

        enum Alert: Equatable {}

        enum DeleteDialog: Equatable {
            case confirm(Comment)
        }
    }

    private enum CancelID { case load }

    @Dependency(\.getCommentsPageUseCase) private var getCommentsPageUseCase
    @Dependency(\.getCommentUseCase) private var getCommentUseCase
    @Dependency(\.toggleLikeCommentUseCase) private var toggleLikeCommentUseCase
    @Dependency(\.deleteCommentUseCase) private var deleteCommentUseCase
    @Dependency(\.sendCommentUseCase) private var sendCommentUseCase
    @Dependency(\.getLikesUseCase) private var getLikesUseCase

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .onAppear:
                guard state.comments.data == nil else { return .none }

                return .send(.reload)

            case .reload:
                state.paginationState = .idle
                state.comments = .loading
                state.page = 1

                guard let movieId = state.id.id else {
                    state.comments = .error(HDrezkaError.unknown)

                    return .cancel(id: CancelID.load)
                }

                return load(movieId: movieId, page: state.page, isInitial: true)

            case .loadMore:
                guard state.paginationState == .idle else { return .none }

                guard let movieId = state.id.id else {
                    state.paginationState = .error(HDrezkaError.unknown)

                    return .none
                }

                state.paginationState = .loading

                return load(movieId: movieId, page: state.page, isInitial: false)

            case let .commentsLoaded(isInitial, .success(comments)):
                state.page += 1

                if isInitial {
                    state.comments = .data(comments)
                } else if !comments.isEmpty {
                    state.comments.append(comments)
                    state.paginationState = .idle
                } else {
                    state.paginationState = .error(HDrezkaError.unknown)
                }

                return .none

            case let .commentsLoaded(isInitial, .failure(error)):
                if isInitial {
                    state.comments = .error(error)
                } else {
                    state.paginationState = .error(error)
                }

                return .none

            case let .linkedCommentTapped(movieId, commentId):
                state.comment = nil
                state.isCommentPresented = true

                guard let movieId = movieId.id else {
                    state.isCommentPresented = false
                    state.alert = .error()

                    return .none
                }

                return .run { send in
                    let result = await Result { try await getCommentUseCase(movieId: movieId, commentId: commentId) }

                    await send(.linkedCommentLoaded(result), animation: .easeInOut)
                }

            case let .linkedCommentLoaded(.success(comment)):
                state.comment = comment

                return .none

            case let .linkedCommentLoaded(.failure(error)):
                state.isCommentPresented = false
                state.alert = .error(error)

                return .none

            case let .likeTapped(comment):
                return .run { send in
                    let result = await Result { try await toggleLikeCommentUseCase(id: comment.commentId) }

                    await send(.likeToggled(comment, result), animation: .easeInOut)
                }

            case let .likeToggled(comment, .success((count, isLiked))):
                if var comments = state.comments.data {
                    for index in comments.indices {
                        comments[index].like(count, isLiked, comment)
                    }

                    state.comments = .data(comments)
                }

                state.comment?.like(count, isLiked, comment)

                return .none

            case let .likeToggled(_, .failure(error)):
                state.alert = .error(error)

                return .none

            case let .likesHovered(comment):
                guard comment.likesCount > 0 else {
                    state.likes[comment.commentId] = nil

                    return .none
                }

                guard state.likes[comment.commentId, default: .init()].likes.count != comment.likesCount else { return .none }

                state.likes[comment.commentId] = .init()

                return .run { send in
                    let result = await Result { try await getLikesUseCase(id: comment.commentId) }

                    await send(.likesLoaded(commentId: comment.commentId, result))
                }

            case let .likesLoaded(commentId, .success(likes)):
                if likes.isEmpty {
                    state.likes = [:]
                    state.alert = .error()
                } else {
                    state.likes[commentId] = .init(likes: likes)
                }

                return .none

            case let .likesLoaded(commentId, .failure(error)):
                state.likes[commentId] = nil
                state.alert = .error(error)

                return .none

            case let .sendComment(name, text):
                guard let postId = state.id.id else {
                    state.alert = .error()

                    return .none
                }

                return .run { [reply = state.reply, adb = state.adb, type = state.type] send in
                    let result = await Result {
                        try await sendCommentUseCase(id: reply, postId: postId, name: name, text: text, adb: adb, type: type)
                    }

                    await send(.commentSent(result))
                }

            case let .commentSent(.success(result)):
                if result.success {
                    state.moderationAlert = .onModeration()
                } else if result.onModeration {
                    state.moderationAlert = .onModeration(message: result.message)
                } else {
                    state.alert = .error(message: result.message)
                }

                return .none

            case let .commentSent(.failure(error)):
                state.alert = .error(error)

                return .none

            case let .deleteTapped(comment):
                state.deleteDialog = .delete(comment)

                return .none

            case let .deleteDialog(.presented(.confirm(comment))):
                guard let hash = comment.deleteHash else {
                    state.alert = .error()

                    return .none
                }

                return .run { send in
                    let result = await Result { try await deleteCommentUseCase(id: comment.commentId, hash: hash) }

                    await send(.commentDeleted(comment, result), animation: .easeInOut)
                }

            case let .commentDeleted(comment, .success((success, message))):
                guard success else {
                    state.alert = .error(message: message)

                    return .none
                }

                if var comments = state.comments.data {
                    if comments.contains(where: { $0.commentId == comment.commentId }) {
                        comments.removeAll(where: { $0.commentId == comment.commentId })
                    } else {
                        for index in comments.indices {
                            comments[index].deleteComment(comment.commentId)
                        }
                    }

                    state.comments = .data(comments)
                }

                return .none

            case let .commentDeleted(_, .failure(error)):
                state.alert = .error(error)

                return .none

            case .alert, .moderationAlert, .deleteDialog:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$moderationAlert, action: \.moderationAlert)
        .ifLet(\.$deleteDialog, action: \.deleteDialog)
    }

    private func load(movieId: String, page: Int, isInitial: Bool) -> Effect<Action> {
        .run { send in
            let result = await Result { try await getCommentsPageUseCase(movieId: movieId, page: page) }

            await send(.commentsLoaded(isInitial: isInitial, result), animation: .easeInOut)
        }
        .cancellable(id: CancelID.load, cancelInFlight: true)
    }
}

extension AlertState where Action == CommentsFeature.Action.Alert {
    static func onModeration(message: String? = nil) -> Self {
        Self(
            title: { TextState("key.comments.success") },
            actions: { ButtonState(role: .cancel) { TextState("key.ok") } },
            message: message.map { message in { TextState(message) } }
        )
    }
}

extension ConfirmationDialogState where Action == CommentsFeature.Action.DeleteDialog {
    static func delete(_ comment: Comment) -> Self {
        Self {
            TextState("key.comment.delete.label")
        } actions: {
            ButtonState(action: .confirm(comment)) { TextState("key.comment.delete.confirm") }
        } message: {
            TextState("key.comment.delete")
        }
    }
}
