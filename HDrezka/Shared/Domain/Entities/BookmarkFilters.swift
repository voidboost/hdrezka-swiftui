import SwiftUI

enum BookmarkFilters: LocalizedStringKey, CaseIterable, Identifiable {
    case added = "key.filters.date"
    case year = "key.filters.year"
    case popular = "key.filters.popular"

    var id: BookmarkFilters { self }
}
