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

    enum Snow: Equatable {
        case hidden
        case falling
        case fading
    }

    @ObservableState
    struct State: Equatable {
        var selectedTab: Tabs = .home

        var path = StackState<Path.State>()

        var home = HomeFeature.State()
        var search = SearchFeature.State()
        var categories = CategoriesFeature.State()
        var collections = CollectionsFeature.State()
        var watchingLater = WatchingLaterFeature.State()
        var bookmarks = BookmarksFeature.State()

        var isSignOutPresented = false
        var isPremiumPresented = false
        var isCommentsRulesPresented = false

        var snow = Snow.hidden

        @Presents var destination: Destination.State?
        @Presents var alert: AlertState<Action.Alert>?
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case path(StackActionOf<Path>)
        case home(HomeFeature.Action)
        case search(SearchFeature.Action)
        case categories(CategoriesFeature.Action)
        case collections(CollectionsFeature.Action)
        case watchingLater(WatchingLaterFeature.Action)
        case bookmarks(BookmarksFeature.Action)
        case appLaunched
        case routeReceived(AppRoute)
        case sessionEventReceived(SessionEvent)
        case signInTapped
        case signOutConfirmed
        case loggedOut(Result<Void, any Error>)
        case loggedInChanged(Bool)
        case snowSettingsChanged(isEnabled: Bool, isForced: Bool)
        case snowSettled
        case destination(PresentationAction<Destination.Action>)
        case alert(PresentationAction<Alert>)

        enum Alert: Equatable {}
    }

    @Dependency(\.appRouter) private var appRouter
    @Dependency(\.sessionEvents) private var sessionEvents
    @Dependency(\.cookiesClient) private var cookiesClient
    @Dependency(\.getVersionUseCase) private var getVersionUseCase
    @Dependency(\.logoutUseCase) private var logoutUseCase
    @Dependency(\.date.now) private var now
    @Dependency(\.calendar) private var calendar

    var body: some ReducerOf<Self> {
        BindingReducer()
            .onChange(of: \.selectedTab) { _, _ in
                Reduce { state, _ in
                    state.path = StackState()

                    return .none
                }
            }

        Scope(state: \.home, action: \.home) { HomeFeature() }
        Scope(state: \.search, action: \.search) { SearchFeature() }
        Scope(state: \.categories, action: \.categories) { CategoriesFeature() }
        Scope(state: \.collections, action: \.collections) { CollectionsFeature() }
        Scope(state: \.watchingLater, action: \.watchingLater) { WatchingLaterFeature() }
        Scope(state: \.bookmarks, action: \.bookmarks) { BookmarksFeature() }

        Reduce { state, action in
            switch action {
            case let .home(.delegate(.push(route))):
                state.path.append(Path.State(route))

                return .none

            case let .path(.element(_, action)):
                if let route = action.route {
                    state.path.append(Path.State(route))
                }

                return .none

            case .appLaunched:
                return .merge(
                    .run { send in
                        for await route in appRouter.routes() {
                            await send(.routeReceived(route))
                        }
                    },
                    .run { send in
                        for await event in sessionEvents.events() {
                            await send(.sessionEventReceived(event))
                        }
                    },
                    .run { _ in
                        await cookiesClient.observe()
                    },
                    .run { send in
                        for await (snow, forceSnow) in Defaults.updates(.snow, .forceSnow, initial: true) {
                            await send(.snowSettingsChanged(isEnabled: snow, isForced: forceSnow))
                        }
                    },
                    .run { _ in
                        let version = try await getVersionUseCase()

                        Defaults[.lastHdrezkaAppVersion] = version
                    }
                )

            case .routeReceived(.signIn), .sessionEventReceived(.loginRequired), .signInTapped:
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

            case .loggedOut(.success):
                return .none

            case let .loggedOut(.failure(error)):
                state.alert = .error(error)

                return .none

            case let .loggedInChanged(isLoggedIn):
                if !isLoggedIn, state.selectedTab.needAccount {
                    state.selectedTab = .home
                }

                return .none

            case let .snowSettingsChanged(isEnabled, isForced):
                let weekOfYear = calendar.component(.weekOfYear, from: now)

                if isEnabled, isForced || weekOfYear <= 2 || weekOfYear >= 51 {
                    state.snow = .falling
                } else if state.snow != .hidden {
                    state.snow = .fading
                }

                return .none

            case .snowSettled:
                if state.snow == .fading {
                    state.snow = .hidden
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

            case .binding, .path, .home, .search, .categories, .collections, .watchingLater, .bookmarks, .destination, .alert:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
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
}

extension AppFeature.Path.Action {
    var route: Destinations? {
        switch self {
        case let .details(.delegate(.push(route))), let .comments(.delegate(.push(route))):
            route
        default:
            nil
        }
    }
}

@MainActor
extension NavigationLink where Destination == Never {
    init<L: View>(route: Destinations, @ViewBuilder label: () -> L) where Label == _NavigationLinkStoreContent<AppFeature.Path.State, L> {
        self.init(state: AppFeature.Path.State(route), label: label)
    }
}
