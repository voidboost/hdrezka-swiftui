import Defaults
import SwiftUI

struct NavigationBar: ViewModifier {
    private let title: String
    private let showBar: Bool
    private let navbar: () -> AnyView
    private let toolbar: () -> AnyView
    
    private let height: CGFloat = 52
    
    @State private var index: Int
    @State private var width: CGFloat = .zero
    @State private var parallax = false
    
    @Environment(AppState.self) private var appState
    @Default(.isLoggedIn) private var isLoggedIn
    @Default(.navigationAnimation) private var navigationAnimation
    
    init(
        title: String,
        showBar: Bool,
        @ViewBuilder navbar: @escaping () -> some View,
        @ViewBuilder toolbar: @escaping () -> some View
    ) {
        self.title = title
        self.showBar = showBar
        self.navbar = { AnyView(navbar()) }
        self.toolbar = { AnyView(toolbar()) }
        self.index = AppState.shared.path.count
    }
    
    func body(content: Content) -> some View {
        content
            .navigationTitle("HDrezka - \(title)")
            .onChange(of: appState.path) {
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
                                
                                navbar()
                            }
                            
                            Spacer()
                            
                            if showBar {
                                Text(title)
                                    .lineLimit(1)
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            
                            Spacer()
                            
                            HStack(alignment: .center, spacing: 5) {
                                toolbar()
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.horizontal, 15)
                        
                        if showBar {
                            Rectangle()
                                .frame(height: 0.4)
                                .foregroundColor(.primary.opacity(0.25))
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
    
    func navigationBar(
        title: String,
        showBar: Bool,
        @ViewBuilder navbar: @escaping () -> some View = { EmptyView() },
        @ViewBuilder toolbar: @escaping () -> some View = { EmptyView() }
    ) -> some View {
        modifier(NavigationBar(title: title, showBar: showBar, navbar: navbar, toolbar: toolbar))
    }
}
