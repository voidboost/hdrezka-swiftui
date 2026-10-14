import SwiftUI

struct Comment: Identifiable, Hashable, Codable {
    let commentId: String
    let date: String
    let author: String
    let photo: String
    let text: AttributedString
    let spoilers: [Spoiler]
    private(set) var replies: [Comment]
    private(set) var likesCount: Int
    private(set) var isLiked: Bool
    let selfComment: Bool
    let isAdmin: Bool
    let deleteHash: String?
    let id: UUID

    init(commentId: String, date: String, author: String, photo: String, text: AttributedString, spoilers: [Spoiler], replies: [Comment], likesCount: Int, isLiked: Bool, selfComment: Bool, isAdmin: Bool, deleteHash: String?, id: UUID = .init()) {
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

    static func == (lhs: Comment, rhs: Comment) -> Bool {
        lhs.id == rhs.id
            && lhs.likesCount == rhs.likesCount
            && lhs.isLiked == rhs.isLiked
            && lhs.replies == rhs.replies
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
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
}

extension Comment {
    enum TextStyles: Hashable {
        case bold
        case italic
        case underline
        case strikethrough
        case link(String)
    }

    struct Spoiler: Identifiable, Hashable, Codable {
        let range: NSRange
        let id: UUID

        init(range: NSRange, id: UUID = .init()) {
            self.range = range
            self.id = id
        }
    }
}
