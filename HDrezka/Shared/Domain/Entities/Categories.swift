import SwiftUI

enum Categories: LocalizedStringKey, CaseIterable, Hashable {
    case hot = "key.filters.hot"
//    case featured = "key.filters.featured"
    case watchingNow = "key.filters.watching_now"
    case newest = "key.filters.newest"
    case latest = "key.filters.latest"
    case popular = "key.filters.popular"
    case soon = "key.filters.soon"

    var localized: String {
        rawValue.toString() ?? ""
    }
}
