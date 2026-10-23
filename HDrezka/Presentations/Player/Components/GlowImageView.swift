import AVKit
import SwiftUI

struct GlowImageView: View {
    @Environment(PlayerEngine.self) private var engine

    var body: some View {
        Group {
            if let glowImage = engine.glowImage {
                glowImage
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(.ultraThinMaterial, in: .rect)
            }
        }
    }
}
