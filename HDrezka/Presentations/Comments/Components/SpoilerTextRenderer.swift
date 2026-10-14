import SwiftUI

struct SpoilerAttribute: TextAttribute {
    let id: UUID
    let revealDate: Date?
}

struct SpoilerTextRenderer: TextRenderer {
    static let revealDuration: TimeInterval = 0.3

    private static let density: Double = 0.35
    private static let speed: Double = 20
    private static let radius: Float = 0.55

    private static let layers: [(angle: Double, speed: Double, turn: Double)] = (0 ..< 8).map { index in
        let seed = (Double(index) * 0.618034).truncatingRemainder(dividingBy: 1)

        return (
            angle: (Double(index) + seed) / 8 * 2 * .pi,
            speed: speed * (Double(index * 3 % 8) + 0.5) / 8,
            turn: (index.isMultiple(of: 2) ? 1 : -1) * (0.2 + 0.4 * seed),
        )
    }

    private static let cell = Float((Double(layers.count) / density).squareRoot())
    private static let shader = ShaderLibrary.default.spoiler

    let date: Date

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        let lines = Array(layout)
        var dust: [(spoiler: SpoilerAttribute, path: Path)] = []

        for (index, line) in lines.enumerated() {
            let bounds = line.typographicBounds.rect
            let top = index > 0 ? (lines[index - 1].typographicBounds.rect.maxY + bounds.minY) / 2 : bounds.minY
            let bottom = index < lines.count - 1 ? (bounds.maxY + lines[index + 1].typographicBounds.rect.minY) / 2 : bounds.maxY

            var lineRect: CGRect?

            func flush() {
                guard let rect = lineRect else { return }

                dust[dust.count - 1].path.addRect(CGRect(x: rect.minX, y: top - 0.5, width: rect.width, height: bottom - top + 1))
                lineRect = nil
            }

            for run in line {
                guard let spoiler = run[SpoilerAttribute.self] else {
                    flush()
                    context.draw(run)
                    continue
                }

                if spoiler.revealDate != nil {
                    var context = context
                    context.opacity = revealProgress(spoiler)
                    context.draw(run)
                }

                let rect = run.typographicBounds.rect

                guard rect.width > 0 else { continue }

                if dust.last?.spoiler.id != spoiler.id {
                    flush()
                    dust.append((spoiler, Path()))
                }

                lineRect = lineRect?.union(rect) ?? rect
            }

            flush()
        }

        guard !dust.isEmpty else { return }

        let time = date.timeIntervalSinceReferenceDate
        let drifts = Self.layers.flatMap { layer in
            let angle = layer.angle + layer.turn * time
            let radius = layer.speed / layer.turn

            return [Float(radius * sin(angle)), Float(-radius * cos(angle))]
        }
        let shader = Self.shader(
            .float(Float(time.truncatingRemainder(dividingBy: 1000))),
            .float(Self.cell),
            .float(Self.radius),
            .floatArray(drifts),
        )

        for (spoiler, path) in dust {
            let opacity = 1 - revealProgress(spoiler)

            guard opacity > 0 else { continue }

            var context = context
            context.opacity = opacity
            context.addFilter(.colorShader(shader))
            context.fill(path, with: .foreground)
        }
    }

    private func revealProgress(_ spoiler: SpoilerAttribute) -> CGFloat {
        spoiler.revealDate.map { min(1, max(0, date.timeIntervalSince($0) / Self.revealDuration)) } ?? 0
    }
}
