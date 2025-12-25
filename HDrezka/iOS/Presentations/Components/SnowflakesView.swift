import Algorithms
import SwiftUI

final class SnowflakesEmitterView: UIView {
    override static var layerClass: AnyClass { CAEmitterLayer.self }

    var emitterLayer: CAEmitterLayer { layer as! CAEmitterLayer }

    override func layoutSubviews() {
        super.layoutSubviews()

        emitterLayer.emitterPosition = CGPoint(x: bounds.midX, y: bounds.minY - Snowflakes.maxRadius)
        emitterLayer.emitterSize = CGSize(width: bounds.width, height: 0)
        emitterLayer.emitterCells?.forEach { emitterCell in
            emitterCell.lifetime = Float((bounds.height + (Snowflakes.maxRadius * 2)) / max(abs(emitterCell.velocity) - abs(emitterCell.velocityRange), 1))
        }
    }
}

struct SnowflakesView: UIViewRepresentable {
    func makeUIView(context _: Context) -> SnowflakesEmitterView {
        let defaultEmitterCell = CAEmitterCell()
        defaultEmitterCell.scale = 0.9
        defaultEmitterCell.scaleRange = 0.1
        defaultEmitterCell.birthRate = 0.2
        defaultEmitterCell.velocity = 20
        defaultEmitterCell.velocityRange = 10
        defaultEmitterCell.spinRange = Angle.degrees(45).radians
        defaultEmitterCell.emissionLongitude = Angle.degrees(180).radians
        defaultEmitterCell.emissionRange = Angle.degrees(30).radians

        let emitterCells = Snowflakes.cgImages.map { cgImage in
            let emitterCell = defaultEmitterCell.copy() as! CAEmitterCell
            emitterCell.contents = cgImage

            return emitterCell
        }

        let snowflakesEmitterView = SnowflakesEmitterView()
        snowflakesEmitterView.emitterLayer.emitterShape = .line
        snowflakesEmitterView.emitterLayer.emitterCells = emitterCells
        snowflakesEmitterView.emitterLayer.seed = UInt32.random(in: UInt32.min ... UInt32.max)
        snowflakesEmitterView.emitterLayer.beginTime = CACurrentMediaTime()

        return snowflakesEmitterView
    }

    func updateUIView(_: SnowflakesEmitterView, context _: Context) {}
}
