import SwiftUI

struct Comment: Identifiable, Hashable {
    let commentId: String
    let date: String
    let author: String
    let photo: String
    let text: AttributedString
    private(set) var replies: [Comment]
    private(set) var likesCount: Int
    private(set) var isLiked: Bool
    let selfComment: Bool
    let isAdmin: Bool
    let deleteHash: String?
    let id: UUID

    init(commentId: String, date: String, author: String, photo: String, text: AttributedString, replies: [Comment], likesCount: Int, isLiked: Bool, selfComment: Bool, isAdmin: Bool, deleteHash: String?, id: UUID = .init()) {
        self.commentId = commentId
        self.date = date
        self.author = author
        self.photo = photo
        self.text = text
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
    enum SpoilerKey: AttributedStringKey {
        typealias Value = UUID

        static let name = "io.silentsea.hdrezka.spoiler"
    }
}
