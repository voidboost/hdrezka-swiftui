import SwiftUI

struct Snowflake: Hashable {
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
    private let creationDate: Date

    init(startX: CGFloat, startY: CGFloat, startRotation: CGFloat, speed: CGFloat, rotationSpeed: CGFloat, opacity: CGFloat, size: CGFloat, noiseSeed: CGFloat, rectCount: Int, raysCount: Int) {
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
        creationDate = .now
    }
}

extension Snowflake {
    func draw(ctx: inout GraphicsContext, size: CGSize, date: Date, noise: Perlin) {
        let time = date.timeIntervalSince(creationDate)

        let x = startX + noise.getValue(noiseSeed + time * 0.1) * 30
        let y = startY + speed * time
        let rotation = startRotation + rotationSpeed * time

        let rangeX = size.width + self.size * 4
        let rangeY = size.height + self.size * 4

        let truncatedX = x.truncatingRemainder(dividingBy: rangeX)
        let posX = (truncatedX < 0 ? truncatedX + rangeX : truncatedX) - (self.size * 2)
        let posY = y.truncatingRemainder(dividingBy: rangeY) - (self.size * 2)

        let angleStep = 360 / CGFloat(raysCount)

        ctx.drawLayer { ctx in
            ctx.translateBy(x: posX, y: posY)
            ctx.rotate(by: .degrees(rotation))

            for ray in 0 ..< raysCount {
                ctx.drawLayer { ctx in
                    ctx.rotate(by: .degrees(angleStep * CGFloat(ray)))

                    for rect in 0 ..< rectCount {
                        let rectWidth = self.size * pow(0.9, CGFloat(rect) + 1)

                        ctx.drawLayer { ctx in
                            ctx.translateBy(x: rectWidth * 0.7 * (CGFloat(rect) + 0.8), y: 0)
                            ctx.rotate(by: .degrees(45))
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
                                with: .color(.teal),
                            )
                        }
                    }
                }
            }
        }
    }
}
