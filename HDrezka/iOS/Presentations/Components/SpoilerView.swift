import SwiftUI

final class EmitterView: UIView {
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
        let emitterLayer = CAEmitterLayer()
        emitterLayer.emitterShape = .rectangle

        let emitterCell = CAEmitterCell()
        emitterCell.contents = UIImage(named: "Speckle")?.cgImage
        emitterCell.contentsScale = 1.8
        emitterCell.emissionRange = .pi * 2
        emitterCell.lifetime = 1
        emitterCell.scale = 0.5
        emitterCell.velocityRange = 20
        emitterCell.alphaRange = 1

        emitterLayer.emitterCells = [emitterCell]
        emitterLayer.seed = UInt32.random(in: UInt32.min ... UInt32.max)

        emitterLayer.beginTime = CACurrentMediaTime()

        layer.addSublayer(emitterLayer)
        self.emitterLayer = emitterLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let emitterLayer else { return }
        emitterLayer.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
        emitterLayer.emitterSize = bounds.size
        emitterLayer.emitterCells?.first?.color = UIColor.label.cgColor

        setBirthRate(Float(bounds.width * bounds.height * 0.2))
    }

    func setBirthRate(_ rate: Float) {
        emitterLayer?.emitterCells?.forEach { $0.birthRate = min(100_000, rate) }
    }
}

struct SpoilerView: UIViewRepresentable {
    func makeUIView(context _: Context) -> EmitterView {
        EmitterView()
    }

    func updateUIView(_ uiView: EmitterView, context _: Context) {
        uiView.setBirthRate(Float(uiView.bounds.width * uiView.bounds.height * 0.2))
    }
}
