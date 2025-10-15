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

    @ViewBuilder
    func content() -> some View {
        NavigationStack {
            switch self {
            case .home:
                HomeView()
                    .id("home")
                    .destinations()
            case .search:
                SearchView()
                    .id("search")
                    .destinations()
            case .categories:
                CategoriesView()
                    .id("categories")
                    .destinations()
            case .collections:
                CollectionsView()
                    .id("collections")
                    .destinations()
            case .watchingLater:
                WatchingLaterView()
                    .id("watching_later")
                    .destinations()
            case .bookmarks:
                BookmarksView()
                    .id("bookmarks")
                    .destinations()
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
            case let .details(movie):
                DetailsView(movie: movie)
                    .id(movie.movieId)
            case let .country(country):
                ListView(country: country)
                    .id(country.countryId)
            case let .category(category):
                ListView(category: category)
                    .id(category)
            case let .genre(genre):
                ListView(genre: genre)
                    .id(genre.genreId)
            case let .collection(collection):
                ListView(collection: collection)
                    .id(collection.collectionId)
            case let .customList(movies, title):
                ListView(movies: movies, title: title)
                    .id(title)
            case let .list(list):
                ListView(list: list)
                    .id(list.listId)
            case let .person(person):
                PersonView(person: person)
                    .id(person.personId)
            case let .comments(details):
                CommentsView(details: details)
                    .id(details.movieId)
            }
        }
    }
}
