import Defaults
import SwiftUI

struct ProfileView: View {
    private let title = String(localized: "key.profile")

    @Environment(AppState.self) private var appState

    @Default(.isLoggedIn) private var isLoggedIn

    var body: some View {
        VStack {
            if !isLoggedIn {
                VStack(spacing: 18) {
                    Text("key.not_logged_in")
                        .font(.title.bold())

                    Text("key.login_description")
                        .multilineTextAlignment(.center)

                    Button {
                        appState.isSignInPresented = true
                    } label: {
                        Label {
                            Text("key.sign_in")
                        } icon: {
                            Image(systemName: "arrow.right")
                        }
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.roundedRectangle(radius: 6))
                }
            } else {
                Form {
                    NavigationLink(value: Destinations.watchingLater) {
                        Label {
                            Text("key.watching_later")
                        } icon: {
                            Image(systemName: "clock.arrow.circlepath")
                        }
                    }

                    NavigationLink(value: Destinations.bookmarks) {
                        Label {
                            Text("key.bookmarks")
                        } icon: {
                            Image(systemName: "bookmark")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 36)
        .transition(.opacity)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                NavigationLink(value: Destinations.licenses) {
                    Image(systemName: "checkmark.seal.text.page")
                }

                if isLoggedIn {
                    Button {
                        appState.isSignOutPresented = true
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }

                NavigationLink(value: Destinations.settings) {
                    Image(systemName: "gear")
                }
            }
        }
        .background(.background)
    }
}
