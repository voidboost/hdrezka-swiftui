import SwiftUI

enum Filters: LocalizedStringKey, CaseIterable, Identifiable {
    case latest = "key.filters.latest"
    case popular = "key.filters.popular"
    case soon = "key.filters.soon"
    case watching = "key.filters.watching_now"

    var id: Filters { self }
}
