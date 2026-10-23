import ComposableArchitecture
import SwiftUI

struct CommentTextView: View {
    private let text: AttributedString

    @State private var revealed: Set<UUID> = []
    @State private var revealing: [UUID: Date] = [:]
    @State private var isVisible = true

    @Environment(StoreOf<CommentsFeature>.self) private var store

    init(text: AttributedString) {
        self.text = text
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

                    store.send(.linkedCommentTapped(movieId: path, commentId: commentId))

                    return .handled
                } else {
                    store.movieDestination = .init(movieId: path)

                    return .handled
                }
            })
    }

    private static let spoilerScheme = "spoiler"

    @ViewBuilder
    private var content: some View {
        if !hasHiddenSpoilers {
            Text(text)
        } else {
            let text = spoilerText

            TimelineView(.animation(minimumInterval: 1 / 60, paused: !isVisible)) { timeline in
                text.textRenderer(SpoilerTextRenderer(date: timeline.date))
            }
            .onScrollVisibilityChange { isVisible in
                self.isVisible = isVisible
            }
        }
    }

    private var hasHiddenSpoilers: Bool {
        text.runs[Comment.SpoilerKey.self].contains { id, _ in
            id.map { !revealed.contains($0) } ?? false
        }
    }

    private var spoilerText: Text {
        text.runs[Comment.SpoilerKey.self].reduce(Text(verbatim: "")) { result, run in
            let (id, range) = run
            var part = AttributedString(text[range])

            guard let id, !revealed.contains(id) else {
                return result + Text(part)
            }

            let revealDate = revealing[id]

            if revealDate == nil {
                part.link = URL(string: "\(Self.spoilerScheme):\(id.uuidString)")
            }

            return result + Text(part).customAttribute(SpoilerAttribute(id: id, revealDate: revealDate))
        }
    }

    private func reveal(_ id: UUID) {
        guard revealing[id] == nil else { return }

        revealing[id] = .now

        Task {
            try? await Task.sleep(for: .seconds(SpoilerTextRenderer.revealDuration))

            revealed.insert(id)
            revealing[id] = nil
        }
    }
}
