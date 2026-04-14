import Alamofire
import Combine
import Defaults
import FactoryKit
import SwiftUI

struct ContentView: View {
    @Injected(\.getVersionUseCase) private var getVersionUseCase
    @Injected(\.logoutUseCase) private var logoutUseCase

    @Default(.mirror) private var mirror
    @Default(.lastHdrezkaAppVersion) private var lastHdrezkaAppVersion
    @Default(.isFirstLaunch) private var isFirstLaunch
    @Default(.snow) private var snow
    @Default(.forceSnow) private var forceSnow

    @Environment(AppState.self) private var appState

    @State private var error: Error?
    @State private var isErrorPresented: Bool = false

    @State private var subscriptions: Set<AnyCancellable> = []

    var body: some View {
        @Bindable var appState = appState

        TabView(selection: $appState.selectedTab) {
            ForEach(Tabs.allCases) { tab in
                Tab(value: tab, role: tab.role) {
                    tab
                } label: {
                    Label {
                        Text(tab.label)
                    } icon: {
                        Image(systemName: tab.image)
                    }
                }
            }
        }
        .tabViewStyle(.tabBarOnly)
        .onAppear {
            getVersionUseCase()
                .receive(on: DispatchQueue.main)
                .sink { _ in } receiveValue: { version in
                    lastHdrezkaAppVersion = version
                }
                .store(in: &subscriptions)
        }
        .sheet(isPresented: $appState.isSignInPresented) {
            SignInSheetView()
                .presentationSizing(.fitted)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $appState.isSignUpPresented) {
            SignUpSheetView()
                .presentationSizing(.fitted)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $appState.isRestorePresented) {
            RestoreSheetView()
                .presentationSizing(.fitted)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .confirmationDialog("key.sign_out.label", isPresented: $appState.isSignOutPresented) {
            Button(role: .destructive) {
                logoutUseCase()
                    .receive(on: DispatchQueue.main)
                    .sink { completion in
                        guard case let .failure(error) = completion else { return }

                        self.error = error
                        isErrorPresented = true
                    } receiveValue: { success in
                        isErrorPresented = !success
                    }
                    .store(in: &subscriptions)
            } label: {
                Text("key.yes")
            }
        } message: {
            Text("key.sign_out.q")
        }
        .alert("key.ops", isPresented: $isErrorPresented) {
            Button(role: .cancel) {} label: {
                Text("key.ok")
            }
        } message: {
            if let error {
                Text(error.localizedDescription)
            }
        }
        .confirmationDialog("key.premium_content", isPresented: $appState.isPremiumPresented) {
            Link("key.buy", destination: (!_mirror.isDefaultValue ? mirror : Const.redirectMirror).appending(path: "payments", directoryHint: .notDirectory))
        } message: {
            Text("key.premium.description")
        }
        .sheet(isPresented: $appState.commentsRulesPresented) {
            CommentsRulesSheetView()
                .presentationSizing(.fitted)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
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
        .overlay {
            let weekOfYear = Calendar.current.component(.weekOfYear, from: .now)

            if snow, weekOfYear <= 2 || weekOfYear >= 51 || forceSnow {
                SnowflakesView()
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
            }
        }
    }
}
