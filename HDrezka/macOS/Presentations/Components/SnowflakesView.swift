import SwiftUI

struct SnowflakesView: View {
    @State private var snowflakes: [Snowflake] = []

    private let noise: Perlin = .init()

    var body: some View {
        TimelineView(.animation) { timeline in
            let currentTime = timeline.date.timeIntervalSinceReferenceDate

            Canvas(rendersAsynchronously: true) { ctx, size in
                for snowflake in snowflakes {
                    snowflake.draw(ctx: &ctx, size: size, time: currentTime, noise: noise)
                }
            } symbols: {
                ForEach(snowflakes) { snowflake in
                    snowflake
                }
            }
        }
        .onGeometryChange(for: CGSize.self) { geometry in
            geometry.size
        } action: { size in
            let targetCount = Int((size.width * size.height) / 20000)

            guard targetCount != snowflakes.count else { return }

            if snowflakes.count > targetCount {
                snowflakes.removeLast(snowflakes.count - targetCount)
            } else if snowflakes.count < targetCount {
                snowflakes.append(contentsOf: (0 ..< (targetCount - snowflakes.count)).map { _ in
                    Snowflake(
                        startX: .random(in: 0 ... size.width),
                        startY: .random(in: -size.height ... 0),
                        startRotation: .random(in: 0 ... 360),
                        speed: .random(in: 10 ... 30),
                        rotationSpeed: .random(in: -25 ... 25),
                        opacity: .random(in: 0.3 ... 0.4),
                        size: .random(in: 4 ... 5),
                        noiseSeed: .random(in: 0 ... 1000),
                        rectCount: .random(in: 2 ... 5),
                        raysCount: .random(in: 5 ... 7),
                    )
                })
            }
        }
    }
}
