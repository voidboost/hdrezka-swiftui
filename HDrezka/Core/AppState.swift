import SwiftUI

@Observable
class AppState {
    @ObservationIgnored static let shared = AppState()

    var isSignInPresented = false
    var isSignUpPresented = false
    var isRestorePresented = false
    var isSignOutPresented = false

    var commentsRulesPresented = false

    var isPremiumPresented = false

    var selectedTab: Tabs = .home

    var window: NSWindow?
}

enum Tabs: Hashable, Identifiable, CaseIterable {
    case home
    case search
    case categories
    case collections
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

    var role: TabRole? {
        switch self {
        case .search:
            .search
        default:
            nil
        }
    }

    @ViewBuilder
    func content() -> some View {
        NavigationStack {
            switch self {
            case .home: HomeView().destinations()
            case .search: SearchView().destinations()
            case .categories: CategoriesView().destinations()
            case .collections: CollectionsView().destinations()
            case .watchingLater: WatchingLaterView().destinations()
            case .bookmarks: BookmarksView().destinations()
            }
        }
    }

    var id: Self { self }
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

    var id: Self { self }
}

extension View {
    @ViewBuilder
    func destinations() -> some View {
        navigationDestination(for: Destinations.self) { destination in
            switch destination {
            case let .details(movie): DetailsView(movie: movie)
            case let .country(country): ListView(country: country)
            case let .category(category): ListView(category: category)
            case let .genre(genre): ListView(genre: genre)
            case let .collection(collection): ListView(collection: collection)
            case let .customList(movies, title): ListView(movies: movies, title: title)
            case let .list(list): ListView(list: list)
            case let .person(person): PersonView(person: person)
            case let .comments(details): CommentsView(details: details)
            }
        }
    }
}
