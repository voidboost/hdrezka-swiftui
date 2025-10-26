import SwiftUI

final class EmitterView: UIView {
    override static var layerClass: AnyClass { CAEmitterLayer.self }

    var emitterLayer: CAEmitterLayer { layer as! CAEmitterLayer }

    override func layoutSubviews() {
        super.layoutSubviews()

        emitterLayer.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
        emitterLayer.emitterSize = bounds.size
        emitterLayer.emitterCells?.first?.color = UIColor.label.cgColor
        emitterLayer.emitterCells?.forEach { $0.birthRate = min(100_000, Float(bounds.width * bounds.height * 0.2)) }
    }
}

struct SpoilerView: UIViewRepresentable {
    func makeUIView(context _: Context) -> EmitterView {
        let emitterView = EmitterView()

        let emitterCell = CAEmitterCell()
        emitterCell.contents = UIImage(named: "Speckle")?.cgImage
        emitterCell.contentsScale = 1.8
        emitterCell.emissionRange = .pi * 2
        emitterCell.lifetime = 1
        emitterCell.scale = 0.5
        emitterCell.velocityRange = 20
        emitterCell.alphaRange = 1

        emitterView.emitterLayer.emitterShape = .rectangle
        emitterView.emitterLayer.emitterCells = [emitterCell]
        emitterView.emitterLayer.seed = UInt32.random(in: .min ... .max)
        emitterView.emitterLayer.beginTime = CACurrentMediaTime()

        return emitterView
    }

    func updateUIView(_: EmitterView, context _: Context) {}
}
