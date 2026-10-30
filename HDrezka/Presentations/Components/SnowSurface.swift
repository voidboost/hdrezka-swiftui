import SwiftUI

enum SnowSurfaceShape: Equatable {
    case rect(cornerRadius: CGFloat = 0)
    case capsule

    func cornerRadius(in size: CGSize) -> CGFloat {
        let limit = min(size.width, size.height) / 2

        return switch self {
        case let .rect(cornerRadius):
            min(cornerRadius, limit)
        case .capsule:
            limit
        }
    }

    func path(in rect: CGRect) -> Path {
        switch self {
        case let .rect(cornerRadius):
            RoundedRectangle(cornerRadius: cornerRadius).path(in: rect)
        case .capsule:
            Capsule().path(in: rect)
        }
    }
}

struct SnowSurface: Equatable {
    var frame: CGRect
    var clip: CGRect
    var cornerRadius: CGFloat
}

@MainActor
@Observable
final class SnowLedge {
    @ObservationIgnored var surface: SnowSurface?
    @ObservationIgnored var screen: UUID?
    @ObservationIgnored weak var view: SnowLedgeView?

    var size: CGSize = .zero
}

@MainActor
final class SnowSurfaces {
    var canvas: CGRect = .zero

    private(set) var ledges: [ObjectIdentifier: SnowLedge] = [:]
    private var screens: [UUID] = []

    func insert(_ ledge: SnowLedge) {
        ledges[ObjectIdentifier(ledge)] = ledge
    }

    func remove(_ ledge: SnowLedge) {
        ledges[ObjectIdentifier(ledge)] = nil
    }

    func show(_ screen: UUID) {
        hide(screen)
        screens.append(screen)
    }

    func hide(_ screen: UUID) {
        screens.removeAll { $0 == screen }
    }

    func isShown(_ ledge: SnowLedge) -> Bool {
        guard let screen = ledge.screen, let active = screens.last else { return true }

        return screen == active
    }
}

extension EnvironmentValues {
    @Entry var snowSurfaces: SnowSurfaces?
    @Entry var snowScreen: UUID?
}

final class SnowLedgeView: NSView {
    let metalLayer = CAMetalLayer()

    var shape: SnowSurfaceShape = .rect() {
        didSet {
            guard shape != oldValue else { return }

            needsLayout = true
        }
    }

    var surfaceHeight: CGFloat = 0 {
        didSet {
            guard surfaceHeight != oldValue else { return }

            needsLayout = true
        }
    }

    var needsRedraw = true

    private let maskLayer = CAShapeLayer()

    override var isFlipped: Bool {
        true
    }

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        wantsLayer = true
        metalLayer.isOpaque = false
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
        metalLayer.mask = maskLayer
    }

    override func makeBackingLayer() -> CALayer {
        metalLayer
    }

    override func hitTest(_: NSPoint) -> NSView? {
        nil
    }

    override func layout() {
        super.layout()

        let scale = window?.backingScaleFactor ?? 2
        let headroom = CGFloat(SnowSimulation.headroom)
        let surface = shape.path(in: CGRect(x: 0, y: headroom, width: bounds.width, height: surfaceHeight))

        metalLayer.contentsScale = scale
        metalLayer.drawableSize = CGSize(width: bounds.width * scale, height: bounds.height * scale)
        maskLayer.frame = bounds
        maskLayer.path = Path(bounds).subtracting(surface).cgPath
        needsRedraw = true
    }

    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()

        needsLayout = true
    }
}

private struct SnowLedgeRepresentable: NSViewRepresentable {
    let ledge: SnowLedge
    let shape: SnowSurfaceShape

    func makeNSView(context _: Context) -> SnowLedgeView {
        let view = SnowLedgeView()
        ledge.view = view

        return view
    }

    func updateNSView(_ view: SnowLedgeView, context _: Context) {
        ledge.view = view
        view.shape = shape
        view.surfaceHeight = ledge.size.height
    }
}

private struct SnowScreenModifier: ViewModifier {
    @Environment(\.snowSurfaces) private var snowSurfaces

    @State private var screen = UUID()

    func body(content: Content) -> some View {
        content
            .environment(\.snowScreen, screen)
            .onAppear {
                snowSurfaces?.show(screen)
            }
            .onDisappear {
                snowSurfaces?.hide(screen)
            }
    }
}

private struct SnowSurfaceModifier: ViewModifier {
    private static let headroom = CGFloat(SnowSimulation.headroom)

    let shape: SnowSurfaceShape

    @Environment(\.snowSurfaces) private var snowSurfaces
    @Environment(\.snowScreen) private var snowScreen

    @State private var ledge = SnowLedge()

    func body(content: Content) -> some View {
        if let snowSurfaces {
            content
                .onGeometryChange(for: SnowSurface.self) { proxy in
                    let frame = proxy.frame(in: .global)
                    var clip = frame.insetBy(dx: -100_000, dy: -100_000)

                    if let bounds = proxy.bounds(of: .scrollView(axis: .horizontal)) {
                        clip.origin.x = frame.minX + bounds.minX
                        clip.size.width = bounds.width
                    }

                    if let bounds = proxy.bounds(of: .scrollView(axis: .vertical)) {
                        clip.origin.y = frame.minY + bounds.minY
                        clip.size.height = bounds.height
                    }

                    return SnowSurface(frame: frame, clip: clip, cornerRadius: shape.cornerRadius(in: frame.size))
                } action: { surface in
                    ledge.surface = surface

                    if ledge.size != surface.frame.size {
                        ledge.size = surface.frame.size
                    }
                }
                .overlay(alignment: .top) {
                    SnowLedgeRepresentable(ledge: ledge, shape: shape)
                        .frame(height: Self.headroom + shape.cornerRadius(in: ledge.size))
                        .offset(y: -Self.headroom)
                        .allowsHitTesting(false)
                }
                .onAppear {
                    ledge.screen = snowScreen
                    snowSurfaces.insert(ledge)
                }
                .onDisappear {
                    snowSurfaces.remove(ledge)
                }
        } else {
            content
        }
    }
}

extension View {
    func snowScreen() -> some View {
        modifier(SnowScreenModifier())
    }

    func snowHeadroom() -> some View {
        scrollClipDisabled()
    }

    func snowSurface(in shape: SnowSurfaceShape = .rect()) -> some View {
        modifier(SnowSurfaceModifier(shape: shape))
    }
}
