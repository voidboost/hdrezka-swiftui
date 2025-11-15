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

    @Environment(AppState.self) private var appState

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
            } label: {
                Text("key.yes")
            }
        } message: {
            Text("key.sign_out.q")
        }
        .confirmationDialog("key.premium_content", isPresented: $appState.isPremiumPresented) {
            Link("key.buy", destination: (mirror != _mirror.defaultValue ? mirror : Const.redirectMirror).appending(path: "payments", directoryHint: .notDirectory))
        } message: {
            Text("key.premium.description")
        }
        .sheet(isPresented: $appState.commentsRulesPresented) {
            CommentsRulesSheet()
                .presentationSizing(.fitted)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}
