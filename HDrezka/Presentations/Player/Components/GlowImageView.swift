import AVKit
import SwiftUI

struct GlowImageView: View {
    @Environment(PlayerEngine.self) private var engine

    private static let shader = ShaderLibrary.default.ambientLight

    var body: some View {
        if let glow = engine.glow {
            GeometryReader { proxy in
                let videoRect = AVMakeRect(aspectRatio: glow.size, insideRect: CGRect(origin: .zero, size: proxy.size))
                let radius = videoRect.width * 0.015
                let margin = radius * 3
                let rect = videoRect.offsetBy(dx: margin, dy: margin)

                Rectangle()
                    .frame(width: proxy.size.width + margin * 2, height: proxy.size.height + margin * 2)
                    .colorEffect(Self.shader(
                        .float4(rect.minX, rect.minY, rect.maxX, rect.maxY),
                        .float4(margin, margin, margin + proxy.size.width, margin + proxy.size.height),
                        .image(Image(decorative: glow.image, scale: 1)),
                        .float4(glow.crop.left, glow.crop.top, glow.crop.right, glow.crop.bottom),
                    ))
                    .blur(radius: radius)
                    .frame(width: proxy.size.width, height: proxy.size.height)
            }
            .allowsHitTesting(false)
            .transition(.opacity)
        }
    }
}
