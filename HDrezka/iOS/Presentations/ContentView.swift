import Alamofire
import Combine
import Defaults
import FactoryKit
import SwiftUI

struct ContentView: View {
    @Injected(\.getVersionUseCase) private var getVersionUseCase

    @Default(.mirror) private var mirror
    @Default(.lastHdrezkaAppVersion) private var lastHdrezkaAppVersion

    @Environment(AppState.self) private var appState

    @State private var subscriptions: Set<AnyCancellable> = []

    var body: some View {
        @Bindable var appState = appState

        TabView(selection: $appState.selectedTab) {
            TabSection {
                ForEach(Tabs.allCases) { tab in
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
        }
        .tabViewStyle(.tabBarOnly)
        .task {
            getVersionUseCase()
                .receive(on: DispatchQueue.main)
                .sink { _ in } receiveValue: { version in
                    lastHdrezkaAppVersion = version
                }
                .store(in: &subscriptions)
        }
//        .sheet(isPresented: $appState.isSignInPresented) {
//            SignInSheetView()
//        }
//        .sheet(isPresented: $appState.isSignUpPresented) {
//            SignUpSheetView()
//        }
//        .sheet(isPresented: $appState.isRestorePresented) {
//            RestoreSheetView()
//        }
//        .confirmationDialog("key.sign_out.label", isPresented: $appState.isSignOutPresented) {
//            Button(role: .destructive) {
//                logoutUseCase()
//            } label: {
//                Text("key.yes")
//            }
//        } message: {
//            Text("key.sign_out.q")
//        }
//        .dialogSeverity(.critical)
//        .confirmationDialog("key.premium_content", isPresented: $appState.isPremiumPresented) {
//            Link("key.buy", destination: (mirror != _mirror.defaultValue ? mirror : Const.redirectMirror).appending(path: "payments", directoryHint: .notDirectory))
//        } message: {
//            Text("key.premium.description")
//        }
//        .sheet(isPresented: $appState.commentsRulesPresented) {
//            CommentsRulesSheet()
//        }
    }
}
