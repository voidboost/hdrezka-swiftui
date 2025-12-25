import Algorithms
import SwiftUI

final class SnowflakesEmitterView: NSView {
    private var emitterLayer: CAEmitterLayer?

    override init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
        setupEmitterLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupEmitterLayer()
    }

    private func setupEmitterLayer() {
        wantsLayer = true

        let defaultEmitterCell = CAEmitterCell()
        defaultEmitterCell.scale = 0.9
        defaultEmitterCell.scaleRange = 0.1
        defaultEmitterCell.birthRate = 0.2
        defaultEmitterCell.velocity = 20
        defaultEmitterCell.velocityRange = 10
        defaultEmitterCell.spinRange = Angle.degrees(45).radians
        defaultEmitterCell.emissionLongitude = Angle.degrees(0).radians
        defaultEmitterCell.emissionRange = Angle.degrees(30).radians

        let emitterCells = Snowflakes.cgImages.map { cgImage in
            let emitterCell = defaultEmitterCell.copy() as! CAEmitterCell
            emitterCell.contents = cgImage

            return emitterCell
        }

        let emitterLayer = CAEmitterLayer()
        emitterLayer.emitterShape = .line
        emitterLayer.emitterCells = emitterCells
        emitterLayer.seed = UInt32.random(in: UInt32.min ... UInt32.max)
        emitterLayer.beginTime = CACurrentMediaTime()

        layer?.addSublayer(emitterLayer)
        self.emitterLayer = emitterLayer
    }

    override func layout() {
        super.layout()

        guard let emitterLayer else { return }

        emitterLayer.emitterPosition = CGPoint(x: bounds.midX, y: bounds.maxY + Snowflakes.maxRadius)
        emitterLayer.emitterSize = CGSize(width: bounds.width, height: 0)
        emitterLayer.emitterCells?.forEach { emitterCell in
            emitterCell.lifetime = Float((bounds.height + (Snowflakes.maxRadius * 2)) / max(abs(emitterCell.velocity) - abs(emitterCell.velocityRange), 1))
        }
    }
}

struct SnowflakesView: NSViewRepresentable {
    func makeNSView(context _: Context) -> SnowflakesEmitterView { SnowflakesEmitterView() }

    func updateNSView(_: SnowflakesEmitterView, context _: Context) {}
}
