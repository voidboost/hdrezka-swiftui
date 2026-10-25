import Foundation

extension Filters {
    var query: String {
        switch self {
        case .latest:
            "last"
        case .popular:
            "popular"
        case .soon:
            "soon"
        case .watching:
            "watching"
        }
    }
}

extension NewFilters {
    var query: String {
        switch self {
        case .latest:
            "last"
        case .popular:
            "popular"
        case .watching:
            "watching"
        }
    }
}

extension BookmarkFilters {
    var query: String {
        switch self {
        case .added:
            "added"
        case .year:
            "year"
        case .popular:
            "popular"
        }
    }
}
