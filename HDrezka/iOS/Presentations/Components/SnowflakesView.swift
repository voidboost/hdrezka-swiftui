import Algorithms
import SwiftUI

final class SnowflakesEmitterView: UIView {
    override static var layerClass: AnyClass { CAEmitterLayer.self }

    var emitterLayer: CAEmitterLayer { layer as! CAEmitterLayer }

    override func layoutSubviews() {
        super.layoutSubviews()

        emitterLayer.emitterPosition = CGPoint(x: bounds.midX, y: bounds.minY - (maxRadius * 2))
        emitterLayer.emitterSize = CGSize(width: bounds.width, height: 0)
        emitterLayer.emitterCells?.forEach { emitterCell in
            emitterCell.lifetime = Float((bounds.height + (maxRadius * 4)) / max(abs(emitterCell.velocity) - abs(emitterCell.velocityRange), 1))
        }
    }

    private func getRadius(size: CGFloat, rectCount: Int) -> CGFloat {
        let lastRectSize = size * pow(0.9, CGFloat(rectCount - 1))
        let lastRectOffset = lastRectSize * 0.7 * (CGFloat(rectCount - 1) + 0.8)
        let halfDiagonal = lastRectSize * sqrt(2) / 2
        return lastRectOffset + halfDiagonal
    }

    private var maxRadius: CGFloat {
        getRadius(size: 5, rectCount: 5)
    }
}

struct SnowflakesView: UIViewRepresentable {
    func makeUIView(context _: Context) -> SnowflakesEmitterView {
        let emitterCells = generateCGImages().map { image in
            let emitterCell = CAEmitterCell()
            emitterCell.contents = image
            emitterCell.scale = 0.9
            emitterCell.scaleRange = 0.1
            emitterCell.birthRate = 0.2
            emitterCell.velocity = 20
            emitterCell.velocityRange = 10
            emitterCell.spinRange = Angle(degrees: 45).radians
            emitterCell.emissionLongitude = Angle(degrees: 180).radians
            emitterCell.emissionRange = Angle(degrees: 30).radians

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

    private func getRadius(size: CGFloat, rectCount: Int) -> CGFloat {
        let lastRectSize = size * pow(0.9, CGFloat(rectCount - 1))
        let lastRectOffset = lastRectSize * 0.7 * (CGFloat(rectCount - 1) + 0.8)
        let halfDiagonal = lastRectSize * sqrt(2) / 2
        return lastRectOffset + halfDiagonal
    }

    private var maxRadius: CGFloat {
        getRadius(size: 5, rectCount: 5)
    }

    private func getAngleStep(raysCount: Int) -> CGFloat {
        360 / CGFloat(raysCount)
    }

    private func createCGImage(size: CGFloat, rectCount: Int, raysCount: Int) -> CGImage? {
        let radius = getRadius(size: size, rectCount: rectCount)
        let angleStep = getAngleStep(raysCount: raysCount)

        guard let context = CGContext(
            data: nil,
            width: Int(radius * 2),
            height: Int(radius * 2),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue,
        ) else {
            return nil
        }

        context.translateBy(x: radius, y: radius)

        for ray in 0 ..< raysCount {
            context.saveGState()

            context.rotate(by: Angle(degrees: angleStep * CGFloat(ray)).radians)

            for rect in 0 ..< rectCount {
                let rectWidth = size * pow(0.9, CGFloat(rect) + 1)

                context.saveGState()

                context.translateBy(x: rectWidth * 0.7 * (CGFloat(rect) + 0.8), y: 0)
                context.rotate(by: Angle(degrees: 45).radians)
                context.setFillColor(UIColor.systemBlue.withAlphaComponent(0.4).cgColor)
                context.fill(
                    CGRect(
                        x: -rectWidth / 2,
                        y: -rectWidth / 2,
                        width: rectWidth,
                        height: rectWidth,
                    ),
                )

                context.restoreGState()
            }

            context.restoreGState()
        }

        return context.makeImage()
    }

    private func generateCGImages() -> [CGImage] {
        product(2 ... 5, 5 ... 7).compactMap { rectCount, raysCount in
            createCGImage(size: 5, rectCount: rectCount, raysCount: raysCount)
        }
    }
}
