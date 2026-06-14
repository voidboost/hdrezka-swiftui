import Algorithms
import SwiftUI

class Snowflakes {
    private enum Const {
        static let size: CGFloat = 5
        static let sizeDecay: CGFloat = 0.9
        static let offsetFactor: CGFloat = 0.7
        static let baseOffset: CGFloat = 0.8
        static let rectRotation: CGFloat = Angle.degrees(45).radians
        static let opacity: CGFloat = 0.4
        static let minRects: Int = 2
        static let maxRects: Int = 5
        static let minRays: Int = 5
        static let maxRays: Int = 7
    }

    private static func getRadius(size: CGFloat, rectCount: Int) -> CGFloat {
        let lastRectSize = size * pow(Const.sizeDecay, CGFloat(rectCount - 1))
        let lastRectOffset = lastRectSize * Const.offsetFactor * (CGFloat(rectCount - 1) + Const.baseOffset)
        let lastRectHalf = lastRectSize / 2 * (abs(cos(Const.rectRotation)) + abs(sin(Const.rectRotation)))
        return lastRectOffset + lastRectHalf
    }

    static var maxRadius: CGFloat {
        getRadius(size: Const.size, rectCount: Const.maxRects)
    }

    private static func getAngleStep(raysCount: Int) -> CGFloat {
        360 / CGFloat(raysCount)
    }

    private static func createCGImage(size: CGFloat, rectCount: Int, raysCount: Int) -> CGImage? {
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

            context.rotate(by: Angle.degrees(angleStep * CGFloat(ray)).radians)

            for rect in 0 ..< rectCount {
                let rectWidth = size * pow(Const.sizeDecay, CGFloat(rect))

                context.saveGState()

                context.translateBy(x: rectWidth * Const.offsetFactor * (CGFloat(rect) + Const.baseOffset), y: 0)
                context.rotate(by: Const.rectRotation)

                #if os(macOS)
                    context.setFillColor(NSColor.systemBlue.withAlphaComponent(Const.opacity).cgColor)
                #else
                    context.setFillColor(UIColor.systemBlue.withAlphaComponent(Const.opacity).cgColor)
                #endif

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

    static var cgImages: [CGImage] {
        product(Const.minRects ... Const.maxRects, Const.minRays ... Const.maxRays).compactMap { rectCount, raysCount in
            createCGImage(size: Const.size, rectCount: rectCount, raysCount: raysCount)
        }
    }
}
