import Foundation

struct SendCommentResult: Hashable {
    let success: Bool
    let onModeration: Bool
    let message: String
}
