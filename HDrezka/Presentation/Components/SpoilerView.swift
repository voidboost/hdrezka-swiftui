import SwiftUI

final class EmitterView: NSView {
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

        let emitterLayer = CAEmitterLayer()
        emitterLayer.emitterShape = .rectangle

        let emitterCell = CAEmitterCell()
        emitterCell.contents = NSImage(named: "Speckle")?.cgImage(forProposedRect: nil, context: nil, hints: nil)
        emitterCell.contentsScale = 1.8
        emitterCell.emissionRange = .pi * 2
        emitterCell.lifetime = 1
        emitterCell.scale = 0.5
        emitterCell.velocityRange = 20
        emitterCell.alphaRange = 1

        emitterLayer.emitterCells = [emitterCell]
        emitterLayer.seed = UInt32.random(in: UInt32.min ... UInt32.max)

        emitterLayer.beginTime = CACurrentMediaTime()

        layer?.addSublayer(emitterLayer)
        self.emitterLayer = emitterLayer
    }

    override func layout() {
        super.layout()
        guard let emitterLayer else { return }
        emitterLayer.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
        emitterLayer.emitterSize = bounds.size

        setBirthRate(Float(bounds.width * bounds.height * 0.2))
    }

    override func updateLayer() {
        super.updateLayer()
        emitterLayer?.emitterCells?.first?.color = NSColor.textColor.cgColor
    }

    func setBirthRate(_ rate: Float) {
        emitterLayer?.emitterCells?.forEach { $0.birthRate = min(100_000, rate) }
    }
}

struct SpoilerView: NSViewRepresentable {
    func makeNSView(context _: Context) -> EmitterView {
        EmitterView()
    }

    func updateNSView(_ nsView: EmitterView, context _: Context) {
        nsView.setBirthRate(Float(nsView.bounds.width * nsView.bounds.height * 0.2))
    }
}
