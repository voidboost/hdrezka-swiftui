import Combine
import FactoryKit
import SwiftUI

class CommentsViewModel: ObservableObject {
    @Injected(\.getCommentsPageUseCase) private var getCommentsPageUseCase
    @Injected(\.getCommentUseCase) private var getCommentUseCase
    @Injected(\.toggleLikeCommentUseCase) private var toggleLikeCommentUseCase
    @Injected(\.deleteCommentUseCase) private var deleteCommentUseCase
    @Injected(\.sendCommentUseCase) private var sendCommentUseCase
    @Injected(\.getLikesUseCase) private var getLikesUseCase

    private var subscriptions: Set<AnyCancellable> = []

    @Published var reply: String?
    @Published var reportComment: Comment?
    @Published var deleteComment: Comment?
    @Published var state: DataState<[Comment]> = .loading
    @Published var paginationState: DataPaginationState = .idle

    private var page = 1

    func getData(movieId: String, isInitial: Bool = true) {
        getCommentsPageUseCase(movieId: movieId, page: page)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                guard case let .failure(error) = completion else { return }

                withAnimation(.easeInOut) {
                    if isInitial {
                        self.state = .error(error as NSError)
                    } else {
                        self.paginationState = .error(error as NSError)
                    }
                }
            } receiveValue: { comments in
                self.page += 1

                withAnimation(.easeInOut) {
                    if isInitial {
                        self.state = .data(comments)
                    } else {
                        if !comments.isEmpty {
                            self.state.append(comments)
                            self.paginationState = .idle
                        } else {
                            self.paginationState = .error(NSError())
                        }
                    }
                }
            }
            .store(in: &subscriptions)
    }

    func load(movieId: String) {
        paginationState = .idle
        state = .loading
        page = 1

        if let movieId = movieId.id {
            getData(movieId: movieId)
        } else {
            withAnimation(.easeInOut) {
                self.state = .error(NSError())
            }
        }
    }

    func loadMore(movieId: String) {
        guard paginationState == .idle else { return }

        withAnimation(.easeInOut) {
            paginationState = .loading
        }

        if let movieId = movieId.id {
            getData(movieId: movieId, isInitial: false)
        } else {
            withAnimation(.easeInOut) {
                self.paginationState = .error(NSError())
            }
        }
    }

    @Published var comment: Comment?
    @Published var isCommentPresented: Bool = false

    func getComment(movieId: String, commentId: String) {
        comment = nil
        isCommentPresented = true

        if let movieId = movieId.id {
            getCommentUseCase(movieId: movieId, commentId: commentId)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    guard case let .failure(error) = completion else { return }

                    self.isCommentPresented = false
                    self.error = error
                    self.isErrorPresented = true
                } receiveValue: { comment in
                    withAnimation(.easeInOut) {
                        self.comment = comment
                    }
                }
                .store(in: &subscriptions)
        } else {
            isCommentPresented = false
            isErrorPresented = true
        }
    }

    @Published var error: Error?
    @Published var isErrorPresented: Bool = false

    func like(comment: Comment) {
        toggleLikeCommentUseCase(id: comment.commentId)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                guard case let .failure(error) = completion else { return }

                self.error = error
                self.isErrorPresented = true
            } receiveValue: { count, isLiked in
                withAnimation(.easeInOut) {
                    if var comments = self.state.data {
                        for i in comments.indices {
                            comments[i].like(count, isLiked, comment)
                        }

                        self.state = .data(comments)
                    }

                    self.comment?.like(count, isLiked, comment)
                }
            }
            .store(in: &subscriptions)
    }

    @Published var isOnModerationPresented: Bool = false
    @Published var message: String?

    func sendComment(name: String?, text: String, postId: String, adb: String?, type: String?) {
        if let postId = postId.id {
            sendCommentUseCase(id: reply, postId: postId, name: name, text: text, adb: adb, type: type)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    guard case let .failure(error) = completion else { return }

                    self.error = error
                    self.isErrorPresented = true
                } receiveValue: { success, onModeration, message in
                    if success {
                        self.isOnModerationPresented = true
                        self.message = nil
                    } else {
                        if onModeration {
                            self.isOnModerationPresented = true
                        } else {
                            self.isErrorPresented = true
                        }

                        self.message = message
                    }
                }
                .store(in: &subscriptions)
        } else {
            isErrorPresented = true
        }
    }

    @Published var likes: [String: (Bool, [Like])] = [:]

    func getLikes(hovering: Bool, comment: Comment) {
        if comment.likesCount > 0 {
            if hovering, likes[comment.commentId]?.1.count != comment.likesCount {
                likes[comment.commentId] = (hovering, [])

                getLikesUseCase(id: comment.commentId)
                    .receive(on: DispatchQueue.main)
                    .sink { completion in
                        guard case let .failure(error) = completion else { return }

                        self.likes = [:]
                        self.error = error
                        self.message = nil
                        self.isErrorPresented = true
                    } receiveValue: { likes in
                        if likes.isEmpty {
                            self.likes = [:]
                            self.error = nil
                            self.message = nil
                            self.isErrorPresented = true
                        } else {
                            withAnimation(.easeInOut) {
                                self.likes[comment.commentId] = (hovering, likes)
                            }
                        }
                    }
                    .store(in: &subscriptions)
            } else {
                likes[comment.commentId]?.0 = hovering
            }
        } else {
            likes[comment.commentId] = nil
        }
    }

    func deleteComment(comment: Comment) {
        if let hash = comment.deleteHash {
            deleteCommentUseCase(id: comment.commentId, hash: hash)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    guard case let .failure(error) = completion else { return }

                    self.error = error
                    self.isErrorPresented = true
                } receiveValue: { success, message in
                    if success {
                        withAnimation(.easeInOut) {
                            if var comments = self.state.data {
                                if comments.contains(where: { $0.commentId == comment.commentId }) {
                                    comments.removeAll(where: { $0.commentId == comment.commentId })
                                } else {
                                    for i in comments.indices {
                                        comments[i].deleteComment(comment.commentId)
                                    }
                                }

                                self.state = .data(comments)
                            }
                        }
                    } else {
                        self.isErrorPresented = true

                        if let message {
                            self.message = message
                        }
                    }
                }
                .store(in: &subscriptions)
        } else {
            isErrorPresented = true
        }
    }
}
