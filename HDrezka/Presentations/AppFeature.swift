import ComposableArchitecture
import Defaults
import SwiftUI

@Reducer
struct AppFeature {
    @Reducer
    enum Path {
        case details(DetailsFeature)
        case list(ListFeature)
        case person(PersonFeature)
        case comments(CommentsFeature)
    }

    @Reducer
    enum Destination {
        case signIn(SignInFeature)
        case signUp(SignUpFeature)
        case restore(RestoreFeature)
    }

    @ObservableState
    struct State: Equatable {
        var selectedTab: Tabs = .home

        var home = HomeFeature.State()
        var homePath = StackState<Path.State>()
        var search = SearchFeature.State()
        var searchPath = StackState<Path.State>()
        var categories = CategoriesFeature.State()
        var categoriesPath = StackState<Path.State>()
        var collections = CollectionsFeature.State()
        var collectionsPath = StackState<Path.State>()
        var watchingLater = WatchingLaterFeature.State()
        var watchingLaterPath = StackState<Path.State>()
        var bookmarks = BookmarksFeature.State()
        var bookmarksPath = StackState<Path.State>()

        var isSignOutPresented = false
        var isPremiumPresented = false
        var isCommentsRulesPresented = false

        @Presents var destination: Destination.State?
        @Presents var alert: AlertState<Action.Alert>?
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case home(HomeFeature.Action)
        case homePath(StackActionOf<Path>)
        case search(SearchFeature.Action)
        case searchPath(StackActionOf<Path>)
        case categories(CategoriesFeature.Action)
        case categoriesPath(StackActionOf<Path>)
        case collections(CollectionsFeature.Action)
        case collectionsPath(StackActionOf<Path>)
        case watchingLater(WatchingLaterFeature.Action)
        case watchingLaterPath(StackActionOf<Path>)
        case bookmarks(BookmarksFeature.Action)
        case bookmarksPath(StackActionOf<Path>)
        case appLaunched
        case routeReceived(AppRoute)
        case signInTapped
        case signOutConfirmed
        case loggedOut(Result<Bool, any Error>)
        case loggedInChanged(Bool)
        case destination(PresentationAction<Destination.Action>)
        case alert(PresentationAction<Alert>)

        enum Alert: Equatable {}
    }

    @Dependency(\.appRouter) private var appRouter
    @Dependency(\.getVersionUseCase) private var getVersionUseCase
    @Dependency(\.logoutUseCase) private var logoutUseCase

    var body: some ReducerOf<Self> {
        BindingReducer()

        Scope(state: \.home, action: \.home) { HomeFeature() }
        Scope(state: \.search, action: \.search) { SearchFeature() }
        Scope(state: \.categories, action: \.categories) { CategoriesFeature() }
        Scope(state: \.collections, action: \.collections) { CollectionsFeature() }
        Scope(state: \.watchingLater, action: \.watchingLater) { WatchingLaterFeature() }
        Scope(state: \.bookmarks, action: \.bookmarks) { BookmarksFeature() }

        Reduce { state, action in
            switch action {
            case let .home(.delegate(.push(route))):
                state.homePath.append(Path.State(route))

                return .none

            case let .homePath(.element(_, action)):
                if let route = action.route { state.homePath.append(Path.State(route)) }

                return .none

            case let .searchPath(.element(_, action)):
                if let route = action.route { state.searchPath.append(Path.State(route)) }

                return .none

            case let .categoriesPath(.element(_, action)):
                if let route = action.route { state.categoriesPath.append(Path.State(route)) }

                return .none

            case let .collectionsPath(.element(_, action)):
                if let route = action.route { state.collectionsPath.append(Path.State(route)) }

                return .none

            case let .watchingLaterPath(.element(_, action)):
                if let route = action.route { state.watchingLaterPath.append(Path.State(route)) }

                return .none

            case let .bookmarksPath(.element(_, action)):
                if let route = action.route { state.bookmarksPath.append(Path.State(route)) }

                return .none

            case .appLaunched:
                return .merge(
                    .run { send in
                        for await route in appRouter.routes() {
                            await send(.routeReceived(route))
                        }
                    },
                    .run { _ in
                        let version = try await getVersionUseCase()

                        Defaults[.lastHdrezkaAppVersion] = version
                    }
                )

            case .routeReceived(.signIn), .signInTapped:
                if case .signIn = state.destination {
                    return .none
                }

                state.destination = .signIn(SignInFeature.State())

                return .none

            case .routeReceived(.premium):
                state.isPremiumPresented = true

                return .none

            case .routeReceived(.commentsRules):
                state.isCommentsRulesPresented = true

                return .none

            case .signOutConfirmed:
                return .run { send in
                    let result = await Result { try await logoutUseCase() }

                    await send(.loggedOut(result))
                }

            case .loggedOut(.success(true)):
                return .none

            case .loggedOut(.success(false)):
                state.alert = .error()

                return .none

            case let .loggedOut(.failure(error)):
                state.alert = .error(error)

                return .none

            case let .loggedInChanged(isLoggedIn):
                if !isLoggedIn, state.selectedTab.needAccount {
                    state.selectedTab = .home
                }

                return .none

            case .destination(.presented(.signIn(.delegate(.showRestore)))):
                state.destination = .restore(RestoreFeature.State())

                return .none

            case .destination(.presented(.signIn(.delegate(.showSignUp)))):
                state.destination = .signUp(SignUpFeature.State())

                return .none

            case .destination(.presented(.signUp(.delegate(.showSignIn)))),
                 .destination(.presented(.restore(.delegate(.showSignIn)))):
                state.destination = .signIn(SignInFeature.State())

                return .none

            case .binding, .home, .homePath, .search, .searchPath, .categories, .categoriesPath,
                 .collections, .collectionsPath, .watchingLater, .watchingLaterPath, .bookmarks, .bookmarksPath,
                 .destination, .alert:
                return .none
            }
        }
        .forEach(\.homePath, action: \.homePath)
        .forEach(\.searchPath, action: \.searchPath)
        .forEach(\.categoriesPath, action: \.categoriesPath)
        .forEach(\.collectionsPath, action: \.collectionsPath)
        .forEach(\.watchingLaterPath, action: \.watchingLaterPath)
        .forEach(\.bookmarksPath, action: \.bookmarksPath)
        .ifLet(\.$destination, action: \.destination)
        .ifLet(\.$alert, action: \.alert)
    }
}

extension AppFeature.Path.State: Equatable {}
extension AppFeature.Destination.State: Equatable {}

extension AppFeature.Path.State {
    init(_ route: Destinations) {
        self = switch route {
        case let .details(movie): .details(DetailsFeature.State(movie: movie))
        case let .country(country): .list(ListFeature.State(source: .country(country)))
        case let .category(category): .list(ListFeature.State(source: .category(category)))
        case let .genre(genre): .list(ListFeature.State(source: .genre(genre)))
        case let .collection(collection): .list(ListFeature.State(source: .collection(collection)))
        case let .customList(movies, title): .list(ListFeature.State(source: .movies(movies, title: title)))
        case let .list(list): .list(ListFeature.State(source: .list(list)))
        case let .person(person): .person(PersonFeature.State(person: person))
        case let .comments(details): .comments(CommentsFeature.State(details: details))
        }
    }

    var analytics: (name: String, className: String) {
        switch self {
        case .details: ("details", "DetailsView")
        case .list: ("list", "ListView")
        case .person: ("person", "PersonView")
        case .comments: ("comments", "CommentsView")
        }
    }
}

extension AppFeature.Path.Action {
    /// A route a screen in the stack asked to push programmatically.
    var route: Destinations? {
        switch self {
        case let .details(.delegate(.push(route))), let .comments(.delegate(.push(route))):
            route
        default:
            nil
        }
    }
}

extension NavigationLink where Destination == Never {
    @MainActor
    init<L: View>(route: Destinations, @ViewBuilder label: () -> L) where Label == _NavigationLinkStoreContent<AppFeature.Path.State, L> {
        self.init(state: AppFeature.Path.State(route), label: label)
    }
}
