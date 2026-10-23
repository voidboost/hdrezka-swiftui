import SwiftUI

enum Tabs: Hashable, Identifiable, CaseIterable {
    case home
    case categories
    case collections
    case search
    case watchingLater
    case bookmarks

    var label: LocalizedStringKey {
        switch self {
        case .home:
            "key.home"
        case .search:
            "key.search"
        case .categories:
            "key.categories"
        case .collections:
            "key.collections"
        case .watchingLater:
            "key.watching_later"
        case .bookmarks:
            "key.bookmarks"
        }
    }

    var image: String {
        switch self {
        case .home:
            "house"
        case .search:
            "magnifyingglass"
        case .categories:
            "square.grid.2x2"
        case .collections:
            "film.stack"
        case .watchingLater:
            "clock.arrow.circlepath"
        case .bookmarks:
            "bookmark"
        }
    }

    var needAccount: Bool {
        switch self {
        case .watchingLater, .bookmarks:
            true
        default:
            false
        }
    }

    var name: String {
        switch self {
        case .home:
            "home"
        case .search:
            "search"
        case .categories:
            "categories"
        case .collections:
            "collections"
        case .watchingLater:
            "watching_later"
        case .bookmarks:
            "bookmarks"
        }
    }

    var className: String {
        switch self {
        case .home:
            "HomeView"
        case .search:
            "SearchView"
        case .categories:
            "CategoriesView"
        case .collections:
            "CollectionsView"
        case .watchingLater:
            "WatchingLaterView"
        case .bookmarks:
            "BookmarksView"
        }
    }

    var id: Self {
        self
    }
}

enum Destinations: Hashable, Identifiable {
    case details(MovieSimple)
    case country(MovieCountry)
    case category(Categories)
    case genre(MovieGenre)
    case collection(MoviesCollection)
    case customList([MovieSimple], String)
    case list(MovieList)
    case person(PersonSimple)
    case comments(MovieDetailed)

    static func fromNamed(_ item: some Named) -> Destinations {
        if let country = item as? MovieCountry {
            return .country(country)
        } else if let genre = item as? MovieGenre {
            return .genre(genre)
        } else if let person = item as? PersonSimple {
            return .person(person)
        } else if let list = item as? MovieList {
            return .list(list)
        } else if let collection = item as? MoviesCollection {
            return .collection(collection)
        }

        fatalError("Need \"named\" implementation")
    }

    var name: String {
        switch self {
        case .details:
            "details"
        case .country, .category, .genre, .collection, .customList, .list:
            "list"
        case .person:
            "person"
        case .comments:
            "comments"
        }
    }

    var className: String {
        switch self {
        case .details:
            "DetailsView"
        case .country, .category, .genre, .collection, .customList, .list:
            "ListView"
        case .person:
            "PersonView"
        case .comments:
            "CommentsView"
        }
    }

    var id: Self {
        self
    }
}
