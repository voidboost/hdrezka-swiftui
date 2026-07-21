import Defaults
import Kingfisher
import Pow
import SwiftUI

struct CommentView: View {
    private let comment: Comment

    init(comment: Comment) {
        self.comment = comment
    }

    @State private var isHovering = false

    @Default(.isLoggedIn) private var isLoggedIn

    @Environment(AppState.self) private var appState
    @Environment(CommentsViewModel.self) private var viewModel

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

                CommentTextView(comment: comment)

                HStack(alignment: .center, spacing: 8) {
                    @Bindable var viewModel = viewModel

                    Button {
                        if isLoggedIn {
                            viewModel.like(comment: comment)
                        } else {
                            appState.isSignInPresented = true
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

                        viewModel.getLikes(comment: comment)
                    }
                    .popover(item: $viewModel.likes[comment.commentId], attachmentAnchor: .rect(.bounds), arrowEdge: .top) { like in
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

                    Button {
                        withAnimation(.easeInOut) {
                            viewModel.reply = (viewModel.reply == comment.commentId) ? nil : comment.commentId
                        }
                    } label: {
                        Group {
                            if viewModel.reply == comment.commentId {
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
                    }
                    .buttonStyle(.plain)

                    if !comment.isAdmin {
                        Button {
                            viewModel.reportComment = comment
                        } label: {
                            Image(systemName: "exclamationmark.bubble.fill")
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

                    Spacer()

                    if comment.deleteHash != nil {
                        Button {
                            viewModel.deleteComment = comment
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

                if viewModel.reply == comment.commentId {
                    CommentTextAreaView()
                }
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
    static func == (lhs: CommentView, rhs: CommentView) -> Bool {
        return lhs.comment.id == rhs.comment.id
    }
}
