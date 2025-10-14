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
    @Default(.isUserPremium) private var isUserPremium
    @Default(.lastHdrezkaAppVersion) private var lastHdrezkaAppVersion

    @Environment(AppState.self) private var appState

    @State private var showDays = false

    @State private var subscriptions: Set<AnyCancellable> = []

    var body: some View {
        @Bindable var appState = appState

        TabView(selection: $appState.selectedTab) {
            TabSection {
                ForEach(Tabs.allCases.filter { !$0.needAccount }) { tab in
                    Tab(value: tab, role: tab.role) {
                        tab.content()
                    } label: {
                        Label {
                            Text(tab.label)
                        } icon: {
                            Image(systemName: tab.image)
                        }
                    }
                }
            } header: {
                Text(Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "HDrezka")
            }

            if isLoggedIn {
                TabSection {
                    ForEach(Tabs.allCases.filter(\.needAccount)) { tab in
                        Tab(value: tab, role: tab.role) {
                            tab.content()
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
                Link(destination: (mirror != _mirror.defaultValue ? mirror : Const.redirectMirror).appending(path: "payments", directoryHint: .notDirectory)) {
                    HStack(spacing: 3) {
                        Image("Premium")
                            .foregroundStyle(Color(red: 222.0 / 255.0, green: 21.0 / 255.0, blue: 226.0 / 255.0))

                        Text("key.premium")
                            .foregroundStyle(Const.premiumGradient)
                    }
                    .conditionalEffect(
                        .repeat(
                            .glow(color: .init(red: 138.0 / 255.0, green: 0.0, blue: 173.0 / 255.0), radius: 10),
                            every: 5,
                        ),
                        condition: isUserPremium <= 3,
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
                    appState.isSignOutPresented = true
                } else {
                    appState.isSignInPresented = true
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
        .onAppear {
            getVersionUseCase()
                .receive(on: DispatchQueue.main)
                .sink { _ in } receiveValue: { version in
                    lastHdrezkaAppVersion = version
                }
                .store(in: &subscriptions)
        }
        .onChange(of: isLoggedIn) {
            if !isLoggedIn, appState.selectedTab.needAccount {
                appState.selectedTab = .home
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
