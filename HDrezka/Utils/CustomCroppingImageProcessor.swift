import Kingfisher
import SwiftUI

struct CustomCroppingImageProcessor: ImageProcessor {
    let identifier: String
    let rect: CGRect

    init(rect: CGRect) {
        self.rect = rect
        identifier = "com.onevcat.Kingfisher.CustomCroppingImageProcessor(\(rect))"
    }

    func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        switch item {
        case let .image(image):
            image.kf.scaled(to: options.scaleFactor)
                .kf.crop(to: rect.size, anchorOn: CGPoint(x: rect.origin.x / (image.size.width - rect.size.width), y: rect.origin.y / (image.size.height - rect.size.height)))
        case .data:
            (DefaultImageProcessor.default |> self).process(item: item, options: options)
        }
    }
}

extension KFOptionSetter {
    func cropping(rect: CGRect) -> Self {
        appendProcessor(
            CustomCroppingImageProcessor(rect: rect),
        )
    }
}
