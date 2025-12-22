import SwiftUI

struct Snowflake: Hashable, Identifiable {
    let id: UUID
    private let startX: CGFloat
    private let startY: CGFloat
    private let startRotation: CGFloat
    private let speed: CGFloat
    private let rotationSpeed: CGFloat
    private let opacity: CGFloat
    private let size: CGFloat
    private let noiseSeed: CGFloat
    private let rectCount: Int
    private let raysCount: Int
    private let creationTime: TimeInterval

    init(id: UUID = .init(), startX: CGFloat, startY: CGFloat, startRotation: CGFloat, speed: CGFloat, rotationSpeed: CGFloat, opacity: CGFloat, size: CGFloat, noiseSeed: CGFloat, rectCount: Int, raysCount: Int) {
        self.id = id
        self.startX = startX
        self.startY = startY
        self.startRotation = startRotation
        self.speed = speed
        self.rotationSpeed = rotationSpeed
        self.opacity = opacity
        self.size = size
        self.noiseSeed = noiseSeed
        self.rectCount = rectCount
        self.raysCount = raysCount
        creationTime = Date.now.timeIntervalSinceReferenceDate
    }
}

extension Snowflake {
    func draw(ctx: inout GraphicsContext, size: CGSize, time: TimeInterval, noise: Perlin) {
        guard let snowflakeSymbol = ctx.resolveSymbol(id: id) else { return }

        let elapsed = time - creationTime

        guard elapsed > 0 else { return }

        let x = startX + noise.getValue(noiseSeed + elapsed * 0.1) * 30
        let y = startY + speed * elapsed
        let rotation = startRotation + rotationSpeed * elapsed

        let rangeX = size.width + radius * 2
        let rangeY = size.height + radius * 2

        let relativeX = x.truncatingRemainder(dividingBy: rangeX)
        let posX = (relativeX < 0 ? relativeX + rangeX : relativeX) - radius
        let posY = y.truncatingRemainder(dividingBy: rangeY) - radius

        let transform = CGAffineTransform.identity
            .translatedBy(x: posX, y: posY)
            .rotated(by: Angle(degrees: rotation).radians)

        ctx.concatenate(transform)

        ctx.draw(snowflakeSymbol, at: .zero, anchor: .center)

        ctx.concatenate(transform.inverted())
    }

    var radius: CGFloat {
        let size = size * pow(0.9, CGFloat(rectCount - 1))
        let offset = size * 0.7 * (CGFloat(rectCount - 1) + 0.8)
        let halfDiagonal = size * sqrt(2) / 2
        return offset + halfDiagonal
    }

    var angleStep: CGFloat {
        360 / CGFloat(raysCount)
    }
}

extension Snowflake: View {
    var body: some View {
        Canvas(rendersAsynchronously: true) { ctx, size in
            let transform = CGAffineTransform.identity.translatedBy(x: size.width / 2, y: size.height / 2)

            ctx.concatenate(transform)

            for ray in 0 ..< raysCount {
                let transform = CGAffineTransform.identity.rotated(by: Angle(degrees: angleStep * CGFloat(ray)).radians)

                ctx.concatenate(transform)

                for rect in 0 ..< rectCount {
                    let rectWidth = self.size * pow(0.9, CGFloat(rect) + 1)

                    let transform = CGAffineTransform.identity
                        .translatedBy(x: rectWidth * 0.7 * (CGFloat(rect) + 0.8), y: 0)
                        .rotated(by: Angle(degrees: 45).radians)

                    ctx.concatenate(transform)

                    ctx.opacity = opacity
                    ctx.fill(
                        Path(
                            CGRect(
                                x: -rectWidth / 2,
                                y: -rectWidth / 2,
                                width: rectWidth,
                                height: rectWidth,
                            ),
                        ),
                        with: .color(.blue),
                    )

                    ctx.concatenate(transform.inverted())
                }

                ctx.concatenate(transform.inverted())
            }

            ctx.concatenate(transform.inverted())
        }
        .frame(width: radius * 2, height: radius * 2)
        .tag(id)
    }
}
