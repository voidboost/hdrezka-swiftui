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
        .frame(minWidth: 1100, minHeight: 600)
        .task {
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

                for tab in Tabs.allCases.filter(\.needAccount) {
                    appState.paths[tab] = nil
                }
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
        .contentShape(.rect(cornerRadius: 6))
        .background(isHovered ? .secondary.opacity(configuration.isPressed ? 0.3 : 0.1) : Color.clear, in: .rect(cornerRadius: 6))
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
        .onHover { over in
            isHovered = over
        }
    }
}

struct SidebarLabelStyle: LabelStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        HStack(alignment: .center, spacing: 7) {
            configuration.icon
                .frame(width: 20)
                .foregroundStyle(Color.accentColor)
            configuration.title
        }
    }
}

struct BlurredView: NSViewRepresentable {
    func makeNSView(context _: Context) -> some NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .sidebar
        view.blendingMode = .behindWindow

        return view
    }

    func updateNSView(_: NSViewType, context _: Context) {}
}
