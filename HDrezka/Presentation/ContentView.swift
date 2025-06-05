import Alamofire
import Combine
import Defaults
import FactoryKit
import Pow
import SwiftSoup
import SwiftUI

struct ContentView: View {
    @Injected(\.logoutUseCase) private var logoutUseCase
    @Injected(\.getVersionUseCase) private var getVersionUseCase

    @Default(.isLoggedIn) private var isLoggedIn
    @Default(.mirror) private var mirror
    @Default(.navigationAnimation) private var navigationAnimation
    @Default(.isUserPremium) private var isUserPremium
    @Default(.lastHdrezkaAppVersion) private var lastHdrezkaAppVersion

    @EnvironmentObject private var appState: AppState

    @Namespace var mainNamespace
    @Environment(\.resetFocus) var resetFocus

    @State private var query = ""

    @State private var showDays = false

    @State private var subscriptions: Set<AnyCancellable> = []

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 20) {
                TextField("key.search", text: $query)
                    .textFieldStyle(.plain)
                    .padding(7)
                    .padding(.horizontal, 25)
                    .background(.quinary)
                    .cornerRadius(5)
                    .overlay {
                        HStack(alignment: .center) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                                .padding(.leading, 8)

                            Spacer()

                            if !query.isEmpty {
                                Button {
                                    query = ""
                                } label: {
                                    Image(systemName: "multiply.circle.fill")
                                        .foregroundStyle(.secondary)
                                        .padding(.trailing, 8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                VStack(alignment: .leading, spacing: 5) {
                    Section {
                        VStack(spacing: 1) {
                            Button {
                                if !appState.path.isEmpty, appState.path.last != .home {
                                    appState.path.append(.home)
                                }
                            } label: {
                                Label {
                                    Text("key.home")
                                } icon: {
                                    Image(systemName: "house")
                                }
                                .font(.system(size: 15, design: .rounded))
                                .labelStyle(SidebarLabelStyle())
                            }
                            .buttonStyle(SidebarButtonStyle())

                            Button {
                                if appState.path.last != .collections {
                                    appState.path.append(.collections)
                                }
                            } label: {
                                Label {
                                    Text("key.collections")
                                } icon: {
                                    Image(systemName: "film.stack")
                                }
                                .font(.system(size: 15, design: .rounded))
                                .labelStyle(SidebarLabelStyle())
                            }
                            .buttonStyle(SidebarButtonStyle())

                            Button {
                                if appState.path.last != .categories {
                                    appState.path.append(.categories)
                                }
                            } label: {
                                Label {
                                    Text("key.categories")
                                } icon: {
                                    Image(systemName: "square.grid.2x2")
                                }
                                .font(.system(size: 15, design: .rounded))
                                .labelStyle(SidebarLabelStyle())
                            }
                            .buttonStyle(SidebarButtonStyle())
                        }
                    } header: {
                        Text(Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "HDrezka")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }

                if isLoggedIn {
                    VStack(alignment: .leading, spacing: 5) {
                        Section {
                            VStack(spacing: 1) {
                                Button {
                                    if appState.path.last != .watchingLater {
                                        appState.path.append(.watchingLater)
                                    }
                                } label: {
                                    Label {
                                        Text("key.watching_later")
                                    } icon: {
                                        Image(systemName: "clock.arrow.circlepath")
                                    }
                                    .font(.system(size: 15, design: .rounded))
                                    .labelStyle(SidebarLabelStyle())
                                }
                                .buttonStyle(SidebarButtonStyle())

                                Button {
                                    if appState.path.last != .bookmarks {
                                        appState.path.append(.bookmarks)
                                    }
                                } label: {
                                    Label {
                                        Text("key.bookmarks")
                                    } icon: {
                                        Image(systemName: "bookmark")
                                    }
                                    .font(.system(size: 15, design: .rounded))
                                    .labelStyle(SidebarLabelStyle())
                                }
                                .buttonStyle(SidebarButtonStyle())
                            }
                        } header: {
                            Text("key.library")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                VStack(alignment: .leading, spacing: 5) {
                    Section {
                        VStack(spacing: 1) {
                            if isLoggedIn {
                                Button {
                                    appState.isSignOutPresented = true
                                } label: {
                                    Label {
                                        Text("key.sign_out")
                                    } icon: {
                                        Image(systemName: "arrow.left")
                                    }
                                    .font(.system(size: 15, design: .rounded))
                                    .labelStyle(SidebarLabelStyle())
                                }
                                .buttonStyle(SidebarButtonStyle())
                            } else {
                                Button {
                                    appState.isSignInPresented = true
                                } label: {
                                    Label {
                                        Text("key.sign_in")
                                    } icon: {
                                        Image(systemName: "arrow.right")
                                    }
                                    .font(.system(size: 15, design: .rounded))
                                    .labelStyle(SidebarLabelStyle())
                                }
                                .buttonStyle(SidebarButtonStyle())
                            }
                        }
                    } header: {
                        HStack {
                            Text("key.account")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(.secondary)

                            Spacer()

                            if let isUserPremium {
                                Link(destination: (mirror != _mirror.defaultValue ? mirror : Const.redirectMirror).appending(path: "payments", directoryHint: .notDirectory)) {
                                    HStack(spacing: 3) {
                                        Image("Premium")
                                            .renderingMode(.template)
                                            .font(.system(size: 11))
                                            .foregroundColor(Color(red: 222.0 / 255.0, green: 21.0 / 255.0, blue: 226.0 / 255.0))

                                        Text("key.premium")
                                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                                            .foregroundStyle(Const.premiumGradient)
                                    }
                                    .conditionalEffect(
                                        .repeat(
                                            .glow(color: .init(red: 138.0 / 255.0, green: 0.0, blue: 173.0 / 255.0), radius: 10),
                                            every: 5
                                        ),
                                        condition: isUserPremium <= 3
                                    )
                                }
                                .buttonStyle(.plain)
                                .onHover { hover in
                                    showDays = hover
                                }
                                .popover(isPresented: $showDays) {
                                    Text("key.days-\(isUserPremium)")
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.secondary)
                                        .padding(10)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.top, 52)
            .padding(.bottom, 15)
            .padding(.horizontal, 10)
            .frame(width: 205)
            .background(BlurredView())

            Divider()

            NavigationStack(path: $appState.path.animationIf(navigationAnimation)) {
                HomeView()
                    .id("home")
                    .navigationDestination(for: Destinations.self) { destination in
                        switch destination {
                        case .home:
                            HomeView()
                                .id("home")
                                .transition(.move(edge: .trailing))
                        case .search:
                            SearchView(searchText: query)
                                .id("search")
                                .transition(.move(edge: .trailing))
                        case .categories:
                            CategoriesView()
                                .id("categories")
                                .transition(.move(edge: .trailing))
                        case .collections:
                            CollectionsView()
                                .id("collections")
                                .transition(.move(edge: .trailing))
                        case .watchingLater:
                            WatchingLaterView()
                                .id("watching_later")
                                .transition(.move(edge: .trailing))
                        case .bookmarks:
                            BookmarksView()
                                .id("bookmarks")
                                .transition(.move(edge: .trailing))
                        case let .details(movie):
                            DetailsView(movie: movie)
                                .id(movie.movieId)
                                .transition(.move(edge: .trailing))
                        case let .country(country):
                            ListView(country: country)
                                .id(country.countryId)
                                .transition(.move(edge: .trailing))
                        case let .category(category):
                            ListView(category: category)
                                .id(category)
                                .transition(.move(edge: .trailing))
                        case let .genre(genre):
                            ListView(genre: genre)
                                .id(genre.genreId)
                                .transition(.move(edge: .trailing))
                        case let .collection(collection):
                            ListView(collection: collection)
                                .id(collection.collectionId)
                                .transition(.move(edge: .trailing))
                        case let .customList(movies, title):
                            ListView(movies: movies, title: title)
                                .id(title)
                                .transition(.move(edge: .trailing))
                        case let .list(list):
                            ListView(list: list)
                                .id(list.listId)
                                .transition(.move(edge: .trailing))
                        case let .person(person):
                            PersonView(person: person)
                                .id(person.personId)
                                .transition(.move(edge: .trailing))
                        case let .comments(details):
                            CommentsView(details: details)
                                .id(details.movieId)
                                .transition(.move(edge: .trailing))
                        }
                    }
            }
        }
        .ignoresSafeArea(edges: .top)
        .frame(minWidth: 1100, minHeight: 600)
        .toolbar(.hidden)
        .task {
            resetFocus(in: mainNamespace)

            getVersionUseCase()
                .receive(on: DispatchQueue.main)
                .sink { _ in } receiveValue: { version in
                    lastHdrezkaAppVersion = version
                }
                .store(in: &subscriptions)
        }
        .customOnChange(of: query.trimmingCharacters(in: .whitespacesAndNewlines)) {
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmed.removeMirror().id != nil {
                if case let .details(movie) = appState.path.last, movie.movieId == trimmed.removeMirror() {
                    return
                }

                appState.path.append(.details(.init(movieId: trimmed.removeMirror())))
            } else if appState.path.last != .search {
                appState.path.append(.search)
            }
        }
        .customOnChange(of: isLoggedIn) {
            while !isLoggedIn, appState.path.last == .watchingLater || appState.path.last == .bookmarks {
                appState.path.removeLast()
            }
        }
        .sheet(isPresented: $appState.isSignInPresented) {
            SignInSheetView()
        }
        .sheet(isPresented: $appState.isSignUpPresented) {
            SignUpSheetView()
        }
        .sheet(isPresented: $appState.isRestorePresented) {
            RestoreSheetView()
        }
        .confirmationDialog("key.sign_out.label", isPresented: $appState.isSignOutPresented) {
            Button(role: .destructive) {
                logoutUseCase()
            } label: {
                Text("key.yes")
            }
        } message: {
            Text("key.sign_out.q")
        }
        .dialogSeverity(.critical)
        .confirmationDialog("key.premium_content", isPresented: $appState.isPremiumPresented) {
            Link("key.buy", destination: (mirror != _mirror.defaultValue ? mirror : Const.redirectMirror).appending(path: "payments", directoryHint: .notDirectory))
        } message: {
            Text("key.premium.description")
        }
        .sheet(isPresented: $appState.commentsRulesPresented) {
            CommentsRulesSheet()
        }
    }
}

struct SidebarButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Self.Configuration) -> some View {
        HStack(alignment: .center) {
            configuration.label

            Spacer()
        }
        .padding(7)
        .frame(maxWidth: .infinity)
        .background(isHovered ? .secondary.opacity(configuration.isPressed ? 0.3 : 0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .contentShape(RoundedRectangle(cornerRadius: 6))
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
        .onHover { over in
            self.isHovered = over
        }
    }
}

struct SidebarLabelStyle: LabelStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        HStack(alignment: .center, spacing: 7) {
            configuration.icon
                .frame(width: 20)
                .foregroundStyle(.accent)
            configuration.title
        }
    }
}

enum Destinations: Hashable {
    case home
    case search
    case categories
    case collections
    case watchingLater
    case bookmarks
    case details(MovieSimple)
    case country(MovieCountry)
    case category(Categories)
    case genre(MovieGenre)
    case collection(MoviesCollection)
    case customList([MovieSimple], String)
    case list(MovieList)
    case person(PersonSimple)
    case comments(MovieDetailed)

    static func fromNamed<T: Named>(_ item: T) -> Destinations {
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

        return .home
    }
}

struct BlurredView: NSViewRepresentable {
    func makeNSView(context: Context) -> some NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .sidebar
        view.blendingMode = .behindWindow

        return view
    }

    func updateNSView(_ nsView: NSViewType, context: Context) {}
}

private extension Binding {
    func animationIf(_ condition: Bool) -> Binding<Value> {
        return condition ? animation(.easeInOut) : self
    }
}
