import SwiftUI

struct CommentTextView: View {
    @State private var comment: Comment

    @State private var revealing: [UUID: Date] = [:]
    @State private var isVisible = true

    @Environment(CommentsViewModel.self) private var viewModel

    init(comment: Comment) {
        self.comment = comment
    }

    var body: some View {
        content
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
            .textSelection(.enabled)
            .environment(\.openURL, OpenURLAction { url in
                if url.scheme == Self.spoilerScheme, let id = UUID(uuidString: url.absoluteString.replacingOccurrences(of: "\(Self.spoilerScheme):", with: "")) {
                    reveal(id)

                    return .handled
                }

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

    private static let spoilerScheme = "spoiler"

    @ViewBuilder
    private var content: some View {
        if comment.spoilers.isEmpty {
            Text(comment.text)
        } else {
            let text = text

            TimelineView(.animation(minimumInterval: 1 / 60, paused: !isVisible)) { timeline in
                text.textRenderer(SpoilerTextRenderer(date: timeline.date))
            }
            .onScrollVisibilityChange { isVisible in
                self.isVisible = isVisible
            }
        }
    }

    private var text: Text {
        let source = comment.text
        var parts: [Text] = []
        var cursor = source.startIndex

        for spoiler in comment.spoilers {
            guard let range = Range(spoiler.range, in: source), range.lowerBound >= cursor else { continue }

            if cursor < range.lowerBound {
                parts.append(Text(AttributedString(source[cursor ..< range.lowerBound])))
            }

            var hidden = AttributedString(source[range])
            let revealDate = revealing[spoiler.id]

            if revealDate == nil {
                hidden.link = URL(string: "\(Self.spoilerScheme):\(spoiler.id.uuidString)")
            }

            parts.append(Text(hidden).customAttribute(SpoilerAttribute(id: spoiler.id, revealDate: revealDate)))

            cursor = range.upperBound
        }

        if cursor < source.endIndex {
            parts.append(Text(AttributedString(source[cursor ..< source.endIndex])))
        }

        return parts.reduce(Text(verbatim: ""), +)
    }

    private func reveal(_ id: UUID) {
        guard revealing[id] == nil else { return }

        revealing[id] = .now

        Task {
            try? await Task.sleep(for: .seconds(SpoilerTextRenderer.revealDuration))

            comment.removeSpoiler(id)
            revealing[id] = nil
        }
    }
}
