import SwiftUI

struct CommentTextView: View {
    @State private var comment: Comment

    @Environment(CommentsViewModel.self) private var viewModel

    init(comment: Comment) {
        self.comment = comment
    }

    var body: some View {
        Text(comment.text)
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
            .textSelection(.enabled)
            .onGeometryChange(for: CGFloat.self) { geometry in
                geometry.size.width
            } action: { width in
                comment.updateRects(containerWidth: width)
            }
            .overlay {
                ForEach(comment.spoilers) { spoiler in
                    ForEach(spoiler.rects.indices, id: \.self) { rectIndex in
                        let rect = spoiler.rects[rectIndex]

//                            Rectangle()
//                                .stroke(.red, lineWidth: 1)
//                                .frame(width: rect.width, height: rect.height)
//                                .position(x: rect.x + rect.width * 0.5, y: rect.y + rect.height * 0.5)

                        SpoilerView()
                            .contentShape(.rect)
                            .background(.background, in: .rect)
                            .clipShape(.rect)
                            .onTapGesture {
                                withAnimation(.easeInOut) {
                                    comment.removeSpoiler(spoiler.id)
                                }
                            }
                            .frame(width: rect.width, height: rect.height)
                            .position(x: rect.midX, y: rect.midY)
                    }
                }
            }
            .environment(\.openURL, OpenURLAction { url in
                guard let path = url.cleanPath, url.id != nil else { return .systemAction }

                if let fragment = url.cleanFragment, fragment.contains("comment") {
                    let commentId = fragment.replacingOccurrences(of: "comment", with: "")

                    viewModel.getComment(movieId: path, commentId: commentId)

                    return .handled
                } else {
                    viewModel.movieDestination = .init(movieId: path)

                    return .handled
                }
            })
    }
}
