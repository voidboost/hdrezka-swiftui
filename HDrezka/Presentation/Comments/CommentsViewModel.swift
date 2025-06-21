import Combine
import FactoryKit
import SwiftUI

@Observable
class CommentsViewModel {
    @ObservationIgnored @LazyInjected(\.getCommentsPageUseCase) private var getCommentsPageUseCase
    @ObservationIgnored @LazyInjected(\.getCommentUseCase) private var getCommentUseCase
    @ObservationIgnored @LazyInjected(\.toggleLikeCommentUseCase) private var toggleLikeCommentUseCase
    @ObservationIgnored @LazyInjected(\.deleteCommentUseCase) private var deleteCommentUseCase
    @ObservationIgnored @LazyInjected(\.sendCommentUseCase) private var sendCommentUseCase
    @ObservationIgnored @LazyInjected(\.getLikesUseCase) private var getLikesUseCase

    @ObservationIgnored private let id: String
    @ObservationIgnored private let adb: String?
    @ObservationIgnored private let type: String?

    init(id: String, adb: String?, type: String?) {
        self.id = id
        self.adb = adb
        self.type = type
    }

    @ObservationIgnored private var subscriptions: Set<AnyCancellable> = []

    private(set) var state: DataState<[Comment]> = .loading
    private(set) var paginationState: DataPaginationState = .idle

    var reply: String?
    var reportComment: Comment?
    var deleteComment: Comment?
    private(set) var comment: Comment?
    var isCommentPresented: Bool = false
    private(set) var error: Error?
    var isErrorPresented: Bool = false
    var isOnModerationPresented: Bool = false
    private(set) var message: String?
    var likes: [String: Likes] = [:]

    @ObservationIgnored private var page = 1

    func getData(movieId: String, isInitial: Bool = true) {
        getCommentsPageUseCase(movieId: movieId, page: page)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                guard case let .failure(error) = completion else { return }

                withAnimation(.easeInOut) {
                    if isInitial {
                        self.state = .error(error)
                    } else {
                        self.paginationState = .error(error)
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
                            self.paginationState = .error(HDrezkaError.unknown)
                        }
                    }
                }
            }
            .store(in: &subscriptions)
    }

    func load() {
        paginationState = .idle
        state = .loading
        page = 1

        if let movieId = id.id {
            getData(movieId: movieId)
        } else {
            withAnimation(.easeInOut) {
                self.state = .error(HDrezkaError.unknown)
            }
        }
    }

    func loadMore() {
        guard paginationState == .idle else { return }

        withAnimation(.easeInOut) {
            paginationState = .loading
        }

        if let movieId = id.id {
            getData(movieId: movieId, isInitial: false)
        } else {
            withAnimation(.easeInOut) {
                self.paginationState = .error(HDrezkaError.unknown)
            }
        }
    }

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
                        for index in comments.indices {
                            comments[index].like(count, isLiked, comment)
                        }

                        self.state = .data(comments)
                    }

                    self.comment?.like(count, isLiked, comment)
                }
            }
            .store(in: &subscriptions)
    }

    func sendComment(name: String?, text: String) {
        if let id = id.id {
            sendCommentUseCase(id: reply, postId: id, name: name, text: text, adb: adb, type: type)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    guard case let .failure(error) = completion else { return }

                    self.error = error
                    self.isErrorPresented = true
                } receiveValue: { result in
                    if result.success {
                        self.isOnModerationPresented = true
                        self.message = nil
                    } else {
                        if result.onModeration {
                            self.isOnModerationPresented = true
                        } else {
                            self.isErrorPresented = true
                        }

                        self.message = result.message
                    }
                }
                .store(in: &subscriptions)
        } else {
            isErrorPresented = true
        }
    }

    func getLikes(comment: Comment) {
        if comment.likesCount > 0 {
            if likes[comment.commentId, default: .init()].likes.count != comment.likesCount {
                likes[comment.commentId, default: .init()] = .init()

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
                                self.likes[comment.commentId, default: .init()] = .init(likes: likes)
                            }
                        }
                    }
                    .store(in: &subscriptions)
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
                                    for index in comments.indices {
                                        comments[index].deleteComment(comment.commentId)
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
