import Defaults
import SwiftUI

struct NavigationBar<Navbar: View, Toolbar: View>: ViewModifier {
    private let title: String
    private let showBar: Bool
    private let navbar: Navbar?
    private let toolbar: Toolbar?

    private let height: CGFloat = 52

    @Environment(AppState.self) private var appState

    @Default(.isLoggedIn) private var isLoggedIn

    init(
        title: String,
        showBar: Bool,
        navbar: (() -> Navbar)?,
        toolbar: (() -> Toolbar)?,
    ) {
        self.title = title
        self.showBar = showBar
        self.navbar = navbar?()
        self.toolbar = toolbar?()
    }

    init(
        title: String,
        showBar: Bool,
        navbar: (() -> Navbar)?,
    ) where Toolbar == EmptyView {
        self.init(title: title, showBar: showBar, navbar: navbar, toolbar: nil)
    }

    func body(content: Content) -> some View {
        content
            .navigationTitle(Text(verbatim: "HDrezka - \(title)"))
            .transition(.opacity)
            .overlay {
                VStack {
                    ZStack(alignment: .bottom) {
                        HStack(alignment: .center, spacing: 8) {
                            HStack(alignment: .center, spacing: 5) {
                                if !appState.path.isEmpty {
                                    Button {
                                        backButtonAction()
                                    } label: {
                                        Image(systemName: "chevron.left")
                                    }
                                    .buttonStyle(NavbarButtonStyle(width: 22, height: 22))
                                }

                                if let navbar {
                                    navbar
                                }
                            }

                            Spacer()

                            if showBar {
                                Text(title)
                                    .lineLimit(1)
                                    .font(.system(size: 15, weight: .semibold))
                            }

                            Spacer()

                            if let toolbar {
                                HStack(alignment: .center, spacing: 5) {
                                    toolbar
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.horizontal, 15)

                        if showBar {
                            Divider()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
                    .background(.bar.opacity(showBar ? 1 : 0))
                    .gesture(WindowDragGesture())

                    Spacer()
                }
            }
            .clipShape(.rect)
    }

    private func backButtonAction() {
        if !appState.path.isEmpty {
            appState.path.removeLast()

            while !isLoggedIn, appState.path.last == .watchingLater || appState.path.last == .bookmarks {
                appState.path.removeLast()
            }
        }
    }
}

struct NavbarButtonStyle: ButtonStyle {
    private let width: CGFloat?
    private let height: CGFloat?
    private let hPadding: CGFloat?
    private let vPadding: CGFloat?

    @State private var isHovered = false

    init(width: CGFloat? = nil, height: CGFloat? = nil, hPadding: CGFloat? = nil, vPadding: CGFloat? = nil) {
        self.width = width
        self.height = height
        self.hPadding = hPadding
        self.vPadding = vPadding
    }

    func makeBody(configuration: Self.Configuration) -> some View {
        ZStack(alignment: .center) {
            configuration.label
                .foregroundColor(configuration.isPressed ? .primary : .secondary)
        }
        .frame(width: width, height: height)
        .padding(.horizontal, hPadding ?? 0)
        .padding(.vertical, vPadding ?? 0)
        .background(isHovered ? .secondary.opacity(configuration.isPressed ? 0.3 : 0.1) : Color.clear)
        .clipShape(.rect(cornerRadius: 6))
        .contentShape(.rect(cornerRadius: 6))
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
        .onHover { isHovered = $0 }
    }
}

extension View {
    func navigationBar(
        title: String,
        showBar: Bool,
        @ViewBuilder navbar: @escaping () -> some View,
        @ViewBuilder toolbar: @escaping () -> some View,
    ) -> some View {
        modifier(NavigationBar(title: title, showBar: showBar, navbar: navbar, toolbar: toolbar))
    }

    func navigationBar(
        title: String,
        showBar: Bool,
        @ViewBuilder navbar: @escaping () -> some View,
    ) -> some View {
        modifier(NavigationBar(title: title, showBar: showBar, navbar: navbar))
    }
}
