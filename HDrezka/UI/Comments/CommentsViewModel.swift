import Combine
import Factory
import SwiftUI

@Observable
class CommentsViewModel {
    @ObservationIgnored
    @Injected(\.movieDetails)
    private var movieDetails

    @ObservationIgnored
    private var subscriptions: Set<AnyCancellable> = []

    var reply: String?
    var reportComment: Comment?
    var deleteComment: Comment?
    var state: DataState<[Comment]> = .loading
    var paginationState: DataPaginationState = .idle

    @ObservationIgnored
    private var page = 1

    func getComments(movieId: String) {
        paginationState = .idle
        state = .loading
        page = 1

        if let movieId = movieId.id {
            movieDetails
                .getCommentsPage(movieId: movieId, page: page)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    guard case let .failure(error) = completion else { return }

                    withAnimation(.easeInOut) {
                        self.state = .error(error as NSError)
                    }
                } receiveValue: { comments in
                    self.page += 1

                    withAnimation(.easeInOut) {
                        self.state = .data(comments)
                    }
                }
                .store(in: &subscriptions)
        } else {
            withAnimation(.easeInOut) {
                self.state = .error(NSError())
            }
        }
    }

    func loadMoreComments(movieId: String) {
        guard paginationState == .idle else {
            return
        }

        withAnimation(.easeInOut) {
            paginationState = .loading
        }

        if let movieId = movieId.id {
            movieDetails
                .getCommentsPage(movieId: movieId, page: page)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    guard case let .failure(error) = completion else { return }

                    withAnimation(.easeInOut) {
                        self.paginationState = .error(error as NSError)
                    }
                } receiveValue: { comments in
                    if !comments.isEmpty {
                        withAnimation(.easeInOut) {
                            self.state.append(comments)
                            self.paginationState = .idle
                        }

                        self.page += 1
                    } else {
                        withAnimation(.easeInOut) {
                            self.paginationState = .error(NSError())
                        }
                    }
                }
                .store(in: &subscriptions)
        } else {
            withAnimation(.easeInOut) {
                self.paginationState = .error(NSError())
            }
        }
    }

    var comment: Comment?
    var isCommentPresented: Bool = false

    func getComment(movieId: String, commentId: String) {
        comment = nil
        isCommentPresented = true

        if let movieId = movieId.id {
            movieDetails
                .getComment(movieId: movieId, commentId: commentId)
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

    var error: Error?
    var isErrorPresented: Bool = false

    func like(comment: Comment) {
        movieDetails
            .toggleLikeComment(id: comment.commentId)
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

    var isOnModerationPresented: Bool = false
    var message: String?

    func sendComment(name: String?, text: String, postId: String, adb: String?, type: String?) {
        if let postId = postId.id {
            movieDetails
                .sendComment(id: reply, postId: postId, name: name, text: text, adb: adb, type: type)
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

    var likes: [String: (Bool, [Like])] = [:]

    func getLikes(hovering: Bool, comment: Comment) {
        if comment.likesCount > 0 {
            if hovering, likes[comment.commentId]?.1.count != comment.likesCount {
                likes[comment.commentId] = (hovering, [])

                movieDetails
                    .getLikes(id: comment.commentId)
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
            movieDetails
                .deleteComment(id: comment.commentId, hash: hash)
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
