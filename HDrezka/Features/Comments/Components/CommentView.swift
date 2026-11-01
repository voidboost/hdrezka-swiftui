import ComposableArchitecture
import Defaults
import Kingfisher
import Pow
import SwiftUI

struct CommentView: View {
    private let comment: Comment

    init(comment: Comment) {
        self.comment = comment
    }

    @Environment(StoreOf<CommentsFeature>.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 8) {
                    KFImage
                        .url(URL(string: comment.photo))
                        .placeholder {
                            Color.gray.shimmering()
                        }
                        .resizable()
                        .loadTransition(.blurReplace(.downUp), animation: .bouncy)
                        .cancelOnDisappear(true)
                        .retry(NetworkRetryStrategy())
                        .scaledToFill()
                        .frame(width: 24, height: 24)
                        .clipShape(.circle)
                        .overlay(.tertiary.opacity(0.2), in: .circle.stroke(lineWidth: 1))

                    Text(comment.author)
                        .font(.body.bold())
                        .textSelection(.enabled)

                    Text(comment.date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                CommentTextView(text: comment.text)

                HStack(alignment: .center, spacing: 8) {
                    CommentLikeButton(comment: comment)

                    CommentReplyButton(commentId: comment.commentId)

                    if !comment.isAdmin {
                        Button {
                            store.send(.reportTapped(comment))
                        } label: {
                            Image(systemName: "exclamationmark.bubble.fill")
                                .foregroundColor(.accentColor)
                                .font(.title2)
                                .frame(height: 28)
                                .padding(.horizontal, 16)
                                .contentShape(.capsule)
                                .background(.tertiary.opacity(0.05), in: .capsule)
                                .overlay(.tertiary.opacity(0.2), in: .capsule.stroke(lineWidth: 1))
                                .snowSurface(in: .capsule)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    if comment.deleteHash != nil {
                        Button {
                            store.send(.deleteTapped(comment))
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.accentColor)
                                .font(.title2)
                                .frame(height: 28)
                                .padding(.horizontal, 16)
                                .contentShape(.capsule)
                                .background(.tertiary.opacity(0.05), in: .capsule)
                                .overlay(.tertiary.opacity(0.2), in: .capsule.stroke(lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }

                CommentReplyArea(commentId: comment.commentId)
            }

            if !comment.replies.isEmpty {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(comment.replies) { reply in
                        CommentView(comment: reply)
                            .equatable()
                    }
                }
                .padding(.leading, 16)
            }
        }
    }
}

extension CommentView: Equatable {
    nonisolated static func == (lhs: CommentView, rhs: CommentView) -> Bool {
        lhs.comment == rhs.comment
    }
}

private struct CommentLikeButton: View {
    let comment: Comment

    @State private var isHovering = false

    @Default(.isLoggedIn) private var isLoggedIn

    @Environment(StoreOf<CommentsFeature>.self) private var store

    var body: some View {
        @Bindable var store = store

        Button {
            if isLoggedIn {
                store.send(.likeTapped(comment))
            } else {
                store.send(.signInRequired)
            }
        } label: {
            HStack(alignment: .center, spacing: 8) {
                if comment.isLiked {
                    Image(systemName: "hand.thumbsup.fill")
                        .foregroundColor(.accentColor)
                        .font(.title2)
                        .transition(.movingParts.pop(Color.accentColor))
                } else {
                    Image(systemName: "hand.thumbsup")
                        .foregroundColor(.accentColor)
                        .font(.title2)
                }

                if comment.likesCount > 0 {
                    Text(verbatim: "\(comment.likesCount)")
                        .font(.system(.body, weight: .semibold).monospacedDigit())
                        .contentTransition(.numericText(value: Double(comment.likesCount)))
                }
            }
            .frame(height: 28)
            .padding(.horizontal, 16)
            .background(.tertiary.opacity(0.05), in: .capsule)
            .overlay(.tertiary.opacity(0.2), in: .capsule.stroke(lineWidth: 1))
            .snowSurface(in: .capsule)
        }
        .buttonStyle(.plain)
        .disabled(comment.selfComment)
        .onHover { isHovering in
            self.isHovering = isHovering
        }
        .task(id: isHovering) {
            guard isHovering else { return }

            try? await Task.sleep(for: .milliseconds(500))

            guard !Task.isCancelled else { return }

            store.send(.likesHovered(comment))
        }
        .popover(item: $store.likes[comment.commentId], attachmentAnchor: .rect(.bounds), arrowEdge: .top) { like in
            VStack(alignment: .center, spacing: 10) {
                if !like.likes.isEmpty {
                    let chunks = like.likes.chunks(ofCount: 8)

                    ForEach(chunks.indices, id: \.self) { chunkIndex in
                        let likes = chunks[chunkIndex]

                        HStack(alignment: .center, spacing: 10) {
                            ForEach(likes) { like in
                                VStack(alignment: .center, spacing: 5) {
                                    KFImage
                                        .url(URL(string: like.photo))
                                        .placeholder {
                                            Color.gray.shimmering()
                                        }
                                        .resizable()
                                        .loadTransition(.blurReplace(.downUp), animation: .bouncy)
                                        .cancelOnDisappear(true)
                                        .retry(NetworkRetryStrategy())
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipShape(.circle)

                                    Text(like.name)
                                        .lineLimit(1)
                                        .font(.body)
                                }
                                .frame(width: 60)
                            }
                        }
                    }
                } else {
                    ProgressView()
                }
            }
            .padding(15)
        }
    }
}

private struct CommentReplyButton: View {
    let commentId: String

    @Environment(StoreOf<CommentsFeature>.self) private var store

    var body: some View {
        Button {
            withAnimation(.easeInOut) {
                store.reply = (store.reply == commentId) ? nil : commentId
            }
        } label: {
            Group {
                if store.reply == commentId {
                    Image(systemName: "chevron.up")
                } else {
                    Text("key.reply")
                }
            }
            .font(.system(.body, weight: .semibold))
            .frame(height: 28)
            .padding(.horizontal, 16)
            .contentShape(.capsule)
            .background(.tertiary.opacity(0.05), in: .capsule)
            .overlay(.tertiary.opacity(0.2), in: .capsule.stroke(lineWidth: 1))
            .snowSurface(in: .capsule)
        }
        .buttonStyle(.plain)
    }
}

private struct CommentReplyArea: View {
    let commentId: String

    @Environment(StoreOf<CommentsFeature>.self) private var store

    var body: some View {
        if store.reply == commentId {
            CommentTextAreaView()
        }
    }
}
