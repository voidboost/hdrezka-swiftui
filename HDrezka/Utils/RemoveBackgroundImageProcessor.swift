import CoreImage.CIFilterBuiltins
import Kingfisher
import SwiftUI
import Vision

struct RemoveBackgroundImageProcessor: ImageProcessor {
    let identifier: String

    init() {
        identifier = "com.onevcat.Kingfisher.RemoveBackgroundImageProcessor(\(UUID().uuidString)"
    }

    func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        switch item {
        case let .image(image):
            image.cgImage(forProposedRect: nil, context: nil, hints: nil)?.removeBackground() ?? image
        case .data:
            (DefaultImageProcessor.default |> self).process(item: item, options: options)
        }
    }
}

extension KFOptionSetter {
    func removeBackground() -> Self {
        appendProcessor(
            RemoveBackgroundImageProcessor(),
        )
    }
}

private extension CGImage {
    func removeBackground() -> NSImage? {
        guard let nsImage = processImage(image: self) else {
            return NSImage(cgImage: self, size: CGSize(width: width, height: height))
        }

        return nsImage
    }

    func processImage(image: CGImage) -> NSImage? {
        let inputImage = CIImage(cgImage: image)
        let handler = VNImageRequestHandler(ciImage: inputImage)
        let request = VNGenerateForegroundInstanceMaskRequest()

        do { try handler.perform([request]) } catch { return nil }

        guard let result = request.results?.first,
              let maskPixelBuffer = try? result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler),
              let outputImage = inputImage.apply(maskImage: CIImage(cvPixelBuffer: maskPixelBuffer))
        else {
            return nil
        }

        return outputImage.render()
    }
}

private extension CIImage {
    func render() -> NSImage? {
        guard let cgImage = CIContext(options: nil).createCGImage(self, from: extent) else { return nil }

        return NSImage(cgImage: cgImage, size: CGSize(width: cgImage.width, height: cgImage.height))
    }

    func apply(maskImage: CIImage) -> CIImage? {
        let filter = CIFilter.blendWithMask()
        filter.inputImage = self
        filter.maskImage = maskImage
        filter.backgroundImage = CIImage.empty()
        return filter.outputImage
    }
}
