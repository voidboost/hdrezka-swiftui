import SwiftUI

struct Bookmark: Identifiable, Codable, Hashable {
    let bookmarkId: Int
    let name: String
    private(set) var count: Int
    private(set) var isChecked: Bool?
    let firstState: Bool?
    let id: UUID

    init(bookmarkId: Int, name: String, count: Int, isChecked: Bool? = nil, firstState: Bool? = nil, id: UUID = .init()) {
        self.bookmarkId = bookmarkId
        self.name = name
        self.count = count
        self.isChecked = isChecked
        self.firstState = firstState
        self.id = id
    }

    static func += (lhs: inout Bookmark, rhs: Int) {
        lhs.count += rhs

        if lhs.isChecked != nil {
            lhs.isChecked = true
        }
    }

    static func -= (lhs: inout Bookmark, rhs: Int) {
        lhs.count -= rhs

        if lhs.isChecked != nil {
            lhs.isChecked = false
        }
    }
}
