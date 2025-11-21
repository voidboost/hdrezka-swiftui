import Defaults
import SwiftUI

struct ProfileView: View {
    private let title = String(localized: "key.profile")

    @Environment(AppState.self) private var appState

    @Environment(\.openURL) private var openURL

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
        .overlay(alignment: .bottom) {
            VStack(alignment: .center, spacing: 50) {
                Button {
                    openURL(Const.helpUkraine)
                } label: {
                    Image(.GS)
                        .resizable()
                        .frame(width: 76, height: 100)
                        .tint(.accentColor)
                        .contentShape(.rect)
                }

                Text("key.id-\(Const.deviceUUID)")
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                NavigationLink(value: Destinations.licenses) {
                    Image(systemName: "checkmark.seal.text.page")
                }

                NavigationLink(value: Destinations.downloads) {
                    Image(systemName: "arrow.down.circle")
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
