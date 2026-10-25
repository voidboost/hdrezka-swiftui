import ComposableArchitecture
import SwiftUI

@Reducer
struct CommentsFeature {
    @ObservableState
    struct State: Equatable {
        let id: String
        let adb: String?
        let type: String?
        let title: String

        var comments: DataState<[Comment]> = .idle
        var pagination = Pagination()

        var reply: String?
        var comment: Comment?
        var isCommentPresented = false
        var likes: [String: Likes] = [:]

        @Presents var alert: AlertState<Action.Alert>?
        @Presents var moderationAlert: AlertState<Action.Alert>?
        @Presents var reportComment: CommentReportFeature.State?
        @Presents var deleteDialog: ConfirmationDialogState<Action.DeleteDialog>?

        init(details: MovieDetailed) {
            id = details.movieId
            adb = details.adb
            type = details.type
            title = details.commentsCount > 0 ? String(localized: "key.comments-\(details.commentsCount)") : String(localized: "key.comments")
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
        case movieLinkTapped(MovieSimple)
        case signInRequired
        case rulesTapped
        case reportTapped(Comment)
        case reportComment(PresentationAction<CommentReportFeature.Action>)
        case deleteTapped(Comment)
        case commentDeleted(Comment, Result<Void, any Error>)
        case alert(PresentationAction<Alert>)
        case moderationAlert(PresentationAction<Alert>)
        case deleteDialog(PresentationAction<DeleteDialog>)

        case delegate(Delegate)

        enum Alert: Equatable {}

        enum Delegate {
            case push(Destinations)
        }

        enum DeleteDialog: Equatable {
            case confirm(Comment)
        }
    }

    private enum CancelID: Hashable {
        case load
        case likes(String)
    }

    @Dependency(\.getCommentsPageUseCase) private var getCommentsPageUseCase
    @Dependency(\.getCommentUseCase) private var getCommentUseCase
    @Dependency(\.toggleLikeCommentUseCase) private var toggleLikeCommentUseCase
    @Dependency(\.deleteCommentUseCase) private var deleteCommentUseCase
    @Dependency(\.sendCommentUseCase) private var sendCommentUseCase
    @Dependency(\.getLikesUseCase) private var getLikesUseCase
    @Dependency(\.appRouter) private var appRouter

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .onAppear:
                guard state.comments.needsLoad else { return .none }

                return .send(.reload)

            case .reload:
                state.pagination.reset()
                state.comments = .loading

                guard let movieId = state.id.id else {
                    state.comments = .error(HDrezkaError.unknown)

                    return .cancel(id: CancelID.load)
                }

                return load(movieId: movieId, page: state.pagination.page, isInitial: true)

            case .loadMore:
                guard state.pagination.state == .idle else { return .none }

                guard let movieId = state.id.id else {
                    state.pagination.state = .error(HDrezkaError.unknown)

                    return .none
                }

                state.pagination.state = .loading

                return load(movieId: movieId, page: state.pagination.page, isInitial: false)

            case let .commentsLoaded(isInitial, result):
                let paginationState = state.comments.receivePage(result, isInitial: isInitial, emptyPageIsError: true)
                state.pagination.update(paginationState, after: result)

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

                if let likes = state.likes[comment.commentId], likes.likes.isEmpty || likes.likes.count == comment.likesCount {
                    return .none
                }

                state.likes[comment.commentId] = .init()

                return .run { send in
                    let result = await Result { try await getLikesUseCase(id: comment.commentId) }

                    await send(.likesLoaded(commentId: comment.commentId, result))
                }
                .cancellable(id: CancelID.likes(comment.commentId), cancelInFlight: true)

            case let .likesLoaded(commentId, result):
                guard state.likes[commentId] != nil else { return .none }

                switch result {
                case let .success(likes) where !likes.isEmpty:
                    state.likes[commentId] = .init(likes: likes)
                case .success:
                    state.likes[commentId] = nil
                    state.alert = .error()
                case let .failure(error):
                    state.likes[commentId] = nil
                    state.alert = .error(error)
                }

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

            case let .movieLinkTapped(movie):
                return .send(.delegate(.push(.details(movie))))

            case .signInRequired:
                return .run { _ in appRouter.present(.signIn) }

            case .rulesTapped:
                return .run { _ in appRouter.present(.commentsRules) }

            case let .reportTapped(comment):
                state.reportComment = CommentReportFeature.State(comment: comment)

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

            case let .commentDeleted(comment, .success):
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

            case .alert, .moderationAlert, .reportComment, .deleteDialog, .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$moderationAlert, action: \.moderationAlert)
        .ifLet(\.$reportComment, action: \.reportComment) {
            CommentReportFeature()
        }
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
