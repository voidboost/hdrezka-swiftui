import SwiftUI

struct Comment: Identifiable, Hashable {
    let commentId: String
    let date: String
    let author: String
    let photo: String
    let text: NSAttributedString
    private(set) var spoilers: [Spoiler]
    private(set) var replies: [Comment]
    private(set) var likesCount: Int
    private(set) var isLiked: Bool
    let selfComment: Bool
    let isAdmin: Bool
    let deleteHash: String?
    let id: UUID

    init(commentId: String, date: String, author: String, photo: String, text: NSAttributedString, spoilers: [Spoiler], replies: [Comment], likesCount: Int, isLiked: Bool, selfComment: Bool, isAdmin: Bool, deleteHash: String?, id: UUID = .init()) {
        self.commentId = commentId
        self.date = date
        self.author = author
        self.photo = photo
        self.text = text
        self.spoilers = spoilers
        self.replies = replies
        self.likesCount = likesCount
        self.isLiked = isLiked
        self.selfComment = selfComment
        self.isAdmin = isAdmin
        self.deleteHash = deleteHash
        self.id = id
    }

    mutating func like(_ count: Int, _ isLiked: Bool, _ comment: Comment) {
        if id == comment.id {
            likesCount = count
            self.isLiked = isLiked
        } else {
            for index in replies.indices {
                replies[index].like(count, isLiked, comment)
            }
        }
    }

    func findComment(_ commentId: String) -> Comment? {
        if self.commentId == commentId {
            return self
        } else {
            for reply in replies {
                if let comment = reply.findComment(commentId) {
                    return comment
                }
            }
        }

        return nil
    }

    mutating func deleteComment(_ commentId: String) {
        if replies.contains(where: { $0.commentId == commentId }) {
            replies.removeAll(where: { $0.commentId == commentId })
        } else {
            for index in replies.indices {
                replies[index].deleteComment(commentId)
            }
        }
    }

    mutating func updateRects(containerWidth: CGFloat) {
        let textStorage = NSTextStorage(attributedString: text)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize(width: containerWidth, height: .greatestFiniteMagnitude))
        textContainer.lineFragmentPadding = .zero

        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)

        for index in spoilers.indices {
            var spoilersRects: [CGRect] = []

            let range = spoilers[index].range

            layoutManager.enumerateLineFragments(forGlyphRange: layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)) { _, usedRect, _, glyphRange, _ in
                let textRect = layoutManager.boundingRect(forGlyphRange: layoutManager.glyphRange(forCharacterRange: NSIntersectionRange(range, layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)), actualCharacterRange: nil), in: textContainer)

                spoilersRects.append(
                    .init(
                        x: abs(max(textRect.origin.x, usedRect.origin.x)),
                        y: abs(max(textRect.origin.y, usedRect.origin.y)),
                        width: abs(min(textRect.size.width, usedRect.size.width) - (textRect.size.width > usedRect.size.width ? abs(textRect.origin.x - usedRect.origin.x) : 0)),
                        height: abs(min(textRect.size.height, usedRect.size.height) - (textRect.size.height > usedRect.size.height ? abs(textRect.origin.y - usedRect.origin.y) : 0)),
                    ),
                )
            }

            spoilers[index].updateRects(
                spoilersRects
                    .reduce(into: [CGRect]()) { result, accum in
                        if let last = result.last, last.width == accum.width, last.origin.x == accum.origin.x {
                            result[result.count - 1] = CGRect(x: last.origin.x, y: last.origin.y, width: last.width, height: last.height + accum.height)
                        } else {
                            result.append(accum)
                        }
                    }
                    .filter { rect in
                        rect.width > 0 && rect.height > 0
                    },
            )
        }
    }

    mutating func removeSpoiler(_ id: UUID) {
        spoilers.removeAll { $0.id == id }
    }
}

extension Comment {
    enum TextStyles: Hashable {
        case bold
        case italic
        case underline
        case strikethrough
        case link(String)
    }

    struct Spoiler: Identifiable, Hashable {
        let range: NSRange
        private(set) var rects: [CGRect]
        let id: UUID

        init(range: NSRange, rects: [CGRect] = [], id: UUID = .init()) {
            self.range = range
            self.rects = rects
            self.id = id
        }

        mutating func updateRects(_ rects: [CGRect]) {
            self.rects = rects
        }
    }
}
