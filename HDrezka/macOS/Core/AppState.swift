import FirebaseAnalytics
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

    @ViewBuilder
    func content() -> some View {
        NavigationStack {
            switch self {
            case .home:
                HomeView()
                    .id("home")
                    .destinations()
                    .analyticsScreen(name: name, class: className)
            case .search:
                SearchView()
                    .id("search")
                    .destinations()
                    .analyticsScreen(name: name, class: className)
            case .categories:
                CategoriesView()
                    .id("categories")
                    .destinations()
                    .analyticsScreen(name: name, class: className)
            case .collections:
                CollectionsView()
                    .id("collections")
                    .destinations()
                    .analyticsScreen(name: name, class: className)
            case .watchingLater:
                WatchingLaterView()
                    .id("watching_later")
                    .destinations()
                    .analyticsScreen(name: name, class: className)
            case .bookmarks:
                BookmarksView()
                    .id("bookmarks")
                    .destinations()
                    .analyticsScreen(name: name, class: className)
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

    var parameters: [String: Any] {
        switch self {
        case let .details(movie):
            movie.dictionary
        case let .country(country):
            country.dictionary
        case let .category(category):
            category.dictionary
        case let .genre(genre):
            genre.dictionary
        case let .collection(collection):
            collection.dictionary
        case let .customList(movies, title):
            ["movies": movies, "title": title]
        case let .list(list):
            list.dictionary
        case let .person(person):
            person.dictionary
        case let .comments(details):
            details.dictionary
        }
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
                    .analyticsScreen(name: destination.name, class: destination.className, extraParameters: destination.parameters)
            case let .country(country):
                ListView(country: country)
                    .id(country.countryId)
                    .analyticsScreen(name: destination.name, class: destination.className, extraParameters: destination.parameters)
            case let .category(category):
                ListView(category: category)
                    .id(category)
                    .analyticsScreen(name: destination.name, class: destination.className, extraParameters: destination.parameters)
            case let .genre(genre):
                ListView(genre: genre)
                    .id(genre.genreId)
                    .analyticsScreen(name: destination.name, class: destination.className, extraParameters: destination.parameters)
            case let .collection(collection):
                ListView(collection: collection)
                    .id(collection.collectionId)
                    .analyticsScreen(name: destination.name, class: destination.className, extraParameters: destination.parameters)
            case let .customList(movies, title):
                ListView(movies: movies, title: title)
                    .id(title)
                    .analyticsScreen(name: destination.name, class: destination.className, extraParameters: destination.parameters)
            case let .list(list):
                ListView(list: list)
                    .id(list.listId)
                    .analyticsScreen(name: destination.name, class: destination.className, extraParameters: destination.parameters)
            case let .person(person):
                PersonView(person: person)
                    .id(person.personId)
                    .analyticsScreen(name: destination.name, class: destination.className, extraParameters: destination.parameters)
            case let .comments(details):
                CommentsView(details: details)
                    .id(details.movieId)
                    .analyticsScreen(name: destination.name, class: destination.className, extraParameters: destination.parameters)
            }
        }
    }
}
