import ComposableArchitecture
import Defaults
import FirebaseAnalytics
import Pow
import SwiftUI

struct ContentView: View {
    @Bindable var store: StoreOf<AppFeature>

    @Default(.isLoggedIn) private var isLoggedIn
    @Default(.mirror) private var mirror
    @Default(.isUserPremium) private var isUserPremium
    @Default(.isFirstLaunch) private var isFirstLaunch
    @Default(.snow) private var snow
    @Default(.forceSnow) private var forceSnow

    @State private var showDays = false

    private var tabs: some View {
        TabView(selection: $store.selectedTab) {
            ForEach(Tabs.allCases.filter { !$0.needAccount }) { tab in
                Tab(value: tab) {
                    stack(for: tab)
                } label: {
                    Label {
                        Text(tab.label)
                    } icon: {
                        Image(systemName: tab.image)
                    }
                }
            }

            if isLoggedIn {
                TabSection {
                    ForEach(Tabs.allCases.filter(\.needAccount)) { tab in
                        Tab(value: tab) {
                            stack(for: tab)
                        } label: {
                            Label {
                                Text(tab.label)
                            } icon: {
                                Image(systemName: tab.image)
                            }
                        }
                    }
                } header: {
                    Text("key.library")
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tabViewSidebarHeader {
            if let isUserPremium {
                Link(destination: (!_mirror.isDefaultValue ? mirror : Const.redirectMirror).appending(path: "payments", directoryHint: .notDirectory)) {
                    HStack(spacing: 3) {
                        Image(.premium)
                            .foregroundStyle(Color(red: 222.0 / 255.0, green: 21.0 / 255.0, blue: 226.0 / 255.0))

                        Text("key.premium")
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
                        .foregroundStyle(.secondary)
                        .padding(10)
                }
            }
        }
        .tabViewSidebarBottomBar {
            Button {
                if isLoggedIn {
                    store.isSignOutPresented = true
                } else {
                    store.send(.signInTapped)
                }
            } label: {
                HStack {
                    Label {
                        if isLoggedIn {
                            Text("key.sign_out")
                        } else {
                            Text("key.sign_in")
                        }
                    } icon: {
                        if isLoggedIn {
                            Image(systemName: "arrow.left")
                        } else {
                            Image(systemName: "arrow.right")
                        }
                    }
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(.primary)

                    Spacer(minLength: 0)
                }
                .padding(.vertical, 3)
            }
            .buttonStyle(.accessoryBar)
            .padding(.vertical, 5)
        }
        .frame(minWidth: 1100, minHeight: 600)
    }

    var body: some View {
        tabs
        .onChange(of: isLoggedIn) {
            store.send(.loggedInChanged(isLoggedIn))
        }
        .sheet(item: $store.scope(state: \.destination?.signIn, action: \.destination.signIn)) { store in
            SignInSheetView(store: store)
        }
        .sheet(item: $store.scope(state: \.destination?.signUp, action: \.destination.signUp)) { store in
            SignUpSheetView(store: store)
        }
        .sheet(item: $store.scope(state: \.destination?.restore, action: \.destination.restore)) { store in
            RestoreSheetView(store: store)
        }
        .confirmationDialog("key.sign_out.label", isPresented: $store.isSignOutPresented) {
            Button(role: .destructive) {
                store.send(.signOutConfirmed)
            } label: {
                Text("key.yes")
            }
        } message: {
            Text("key.sign_out.q")
        }
        .dialogSeverity(.critical)
        .alert($store.scope(state: \.alert, action: \.alert))
        .confirmationDialog("key.premium_content", isPresented: $store.isPremiumPresented) {
            Link("key.buy", destination: (!_mirror.isDefaultValue ? mirror : Const.redirectMirror).appending(path: "payments", directoryHint: .notDirectory))
        } message: {
            Text("key.premium.description")
        }
        .sheet(isPresented: $store.isCommentsRulesPresented) {
            CommentsRulesSheetView()
        }
        .alert("key.disclaimer", isPresented: $isFirstLaunch) {
            Link(destination: (!_mirror.isDefaultValue ? mirror : Const.redirectMirror).appending(path: "rules/", directoryHint: .notDirectory)) {
                Text("key.site.rules")
            }

            Button(role: .cancel) {} label: {
                Text("key.ok")
            }
        } message: {
            Text("key.disclaimer.description")
        }
        .dialogSeverity(.critical)
        .overlay {
            let weekOfYear = Calendar.current.component(.weekOfYear, from: .now)

            if snow, weekOfYear <= 2 || weekOfYear >= 51 || forceSnow {
                SnowflakesView()
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
            }
        }
    }

    private func stack(for tab: Tabs) -> some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            root(for: tab)
                .analyticsScreen(name: tab.name, class: tab.className)
        } destination: { store in
            PathView(store: store)
        }
    }

    @ViewBuilder
    private func root(for tab: Tabs) -> some View {
        switch tab {
        case .home:
            HomeView(store: store.scope(state: \.home, action: \.home))
        case .search:
            SearchView(store: store.scope(state: \.search, action: \.search))
        case .categories:
            CategoriesView(store: store.scope(state: \.categories, action: \.categories))
        case .collections:
            CollectionsView(store: store.scope(state: \.collections, action: \.collections))
        case .watchingLater:
            WatchingLaterView(store: store.scope(state: \.watchingLater, action: \.watchingLater))
        case .bookmarks:
            BookmarksView(store: store.scope(state: \.bookmarks, action: \.bookmarks))
        }
    }
}

private struct PathView: View {
    let store: StoreOf<AppFeature.Path>

    var body: some View {
        let analytics = store.state.analytics

        Group {
            switch store.case {
            case let .details(store):
                DetailsView(store: store)
            case let .list(store):
                ListView(store: store)
            case let .person(store):
                PersonView(store: store)
            case let .comments(store):
                CommentsView(store: store)
            }
        }
        .analyticsScreen(name: analytics.name, class: analytics.className)
    }
}
