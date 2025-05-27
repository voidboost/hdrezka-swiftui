import Defaults
import SwiftUI

struct NavigationBar<Navbar: View, Toolbar: View>: ViewModifier {
    private let title: String
    private let showBar: Bool
    private let navbar: Navbar?
    private let toolbar: Toolbar?
    
    private let height: CGFloat = 52
    
    @State private var index: Int
    @State private var width: CGFloat = .zero
    @State private var parallax = false
    
    @EnvironmentObject private var appState: AppState

    @Default(.isLoggedIn) private var isLoggedIn
    @Default(.navigationAnimation) private var navigationAnimation
    
    init(
        title: String,
        showBar: Bool,
        navbar: (() -> Navbar)?,
        toolbar: (() -> Toolbar)?
    ) {
        self.title = title
        self.showBar = showBar
        self.navbar = navbar?()
        self.toolbar = toolbar?()
        self.index = AppState.shared.path.count
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
            .customOnChange(of: appState.path) {
                if parallax != (appState.path.count != index) {
                    withAnimation(.easeInOut) {
                        parallax = appState.path.count > index
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
            .overlay {
                VStack {
                    ZStack(alignment: .bottom) {
                        HStack(alignment: .center, spacing: 8) {
                            HStack(alignment: .center, spacing: 5) {
                                if index > 0 {
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
                    .windowDraggable()
                    
                    Spacer()
                }
            }
            .onGeometryChange(for: CGFloat.self) { geometry in
                geometry.size.width
            } action: { width in
                self.width = width
            }
            .offset(x: parallax && navigationAnimation ? width / -4 : 0)
            .clipShape(Rectangle())
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
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .contentShape(RoundedRectangle(cornerRadius: 6))
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
        .onHover { isHovered = $0 }
    }
}

extension View {
    @ViewBuilder
    func windowDraggable(_ enabled: Bool = true) -> some View {
        if enabled, #available(macOS 15.0, *) {
            self.gesture(WindowDragGesture())
        } else {
            self
        }
    }
    
    func navigationBar<Navbar: View, Toolbar: View>(
        title: String,
        showBar: Bool,
        @ViewBuilder navbar: @escaping () -> Navbar,
        @ViewBuilder toolbar: @escaping () -> Toolbar
    ) -> some View {
        modifier(NavigationBar(title: title, showBar: showBar, navbar: navbar, toolbar: toolbar))
    }
    
    func navigationBar<Navbar: View>(
        title: String,
        showBar: Bool,
        @ViewBuilder navbar: @escaping () -> Navbar
    ) -> some View {
        modifier(NavigationBar(title: title, showBar: showBar, navbar: navbar))
    }
}
