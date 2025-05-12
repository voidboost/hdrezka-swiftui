import SwiftUI

extension AnyTransition {
    static func wipe(reversed: Bool = false, blurRadius: CGFloat = 0) -> AnyTransition {
        .modifier(
            active: Wipe(reversed: reversed, blurRadius: blurRadius, progress: 0),
            identity: Wipe(reversed: reversed, blurRadius: blurRadius, progress: 1)
        )
    }
}

private struct Wipe: ViewModifier, Animatable, AnimatableModifier {
    private let reversed: Bool
    var animatableData: AnimatablePair<CGFloat, CGFloat>

    init(reversed: Bool, blurRadius: CGFloat = 0, progress: CGFloat) {
        self.reversed = reversed
        self.animatableData = AnimatableData(progress, clamp(0, blurRadius, 30))
    }

    private var progress: CGFloat {
        animatableData.first
    }

    private var blurRadius: CGFloat {
        animatableData.second
    }

    func body(content: Content) -> some View {
        content
            .mask(
                GeometryReader { proxy in
                    mask(size: proxy.size)
                        .blur(radius: blurRadius * (1 - progress))
                        .compositingGroup()
                }
                .padding(-blurRadius)
                .animation(nil, value: animatableData)
            )
    }

    @ViewBuilder
    func mask(size: CGSize) -> some View {
        let angle = Angle.radians(atan2(size.height, size.width) + (reversed ? Double.pi : 0))
        let bounds = CGRect(origin: .zero, size: size).boundingBox(at: angle)

        ZStack(alignment: .leading) {
            Color.clear

            Rectangle()
                .frame(width: progress * bounds.width)
        }
        .frame(width: bounds.width, height: bounds.height)
        .position(x: bounds.midX, y: bounds.midY)
        .rotationEffect(angle)
        .animation(nil, value: progress)
        .animation(nil, value: angle)
    }
}

extension CGRect {
    init(center: CGPoint, size: CGSize) {
        let origin = CGPoint(
            x: center.x - size.width / 2,
            y: center.y - size.height / 2
        )

        self.init(origin: origin, size: size)
    }

    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }

    func boundingBox(at angle: Angle) -> CGRect {
        CGRect(center: center, size: size.boundingSize(at: angle))
    }
}

extension CGSize {
    var area: CGFloat {
        width * height
    }

    func boundingSize(at angle: Angle) -> CGSize {
        var theta: Double = angle.radians

        let sizeA = CGSize(
            width: abs(width * cos(Double(theta)) + height * sin(Double(theta))),
            height: abs(width * sin(Double(theta)) + height * cos(Double(theta)))
        )

        theta += .pi * 0.5

        let sizeB = CGSize(
            width: abs(width * sin(Double(theta)) + height * cos(Double(theta))),
            height: abs(width * cos(Double(theta)) + height * sin(Double(theta)))
        )

        if sizeA.area > sizeB.area {
            return sizeA
        } else {
            return sizeB
        }
    }
}

func clamp<C: Comparable>(_ min: C, _ value: C, _ max: C) -> C {
    Swift.max(min, Swift.min(value, max))
}
