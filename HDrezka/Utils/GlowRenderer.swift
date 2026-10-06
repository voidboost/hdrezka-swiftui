import AVKit
import CoreImage

final class GlowRenderer: @unchecked Sendable {
    let videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)])

    var onImage: ((CGImage) -> Void)?

    private let ciContext = CIContext(options: [.useSoftwareRenderer: false, .cacheIntermediates: false])
    private let queue = DispatchQueue(label: "io.silentsea.hdrezka.glowQueue", qos: .userInitiated)
    private var isRendering = false

    func render(at time: CMTime) {
        guard !isRendering, videoOutput.hasNewPixelBuffer(forItemTime: time) else { return }

        isRendering = true

        queue.async { [self] in
            let image = makeImage(at: time)

            DispatchQueue.main.async { [self] in
                isRendering = false

                if let image {
                    onImage?(image)
                }
            }
        }
    }

    private func makeImage(at time: CMTime) -> CGImage? {
        if #available(macOS 26.0, *) {
            guard let pixelBuffer = videoOutput.pixelBufferAndDisplayTime(forItemTime: time).pixelBuffer else { return nil }

            return pixelBuffer.withUnsafeBuffer { buffer in
                downscale(CIImage(cvPixelBuffer: buffer))
            }
        } else {
            guard let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: time, itemTimeForDisplay: nil) else { return nil }

            return downscale(CIImage(cvPixelBuffer: pixelBuffer))
        }
    }

    private func downscale(_ ciImage: CIImage) -> CGImage? {
        let scaleTransform = CGAffineTransform(scaleX: 0.25, y: 0.25)

        let transformed = ciImage
            .transformed(by: scaleTransform, highQualityDownsample: false)
            .clampedToExtent()
            .cropped(to: ciImage.extent.applying(scaleTransform))

        return ciContext.createCGImage(transformed, from: transformed.extent)
    }
}
