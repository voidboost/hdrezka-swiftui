import AVKit
import SwiftUI

struct GlowImageView: View {
    @Environment(PlayerViewModel.self) private var viewModel

    var body: some View {
        Group {
            if let glowImage = viewModel.glowImage {
                glowImage
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(.ultraThinMaterial, in: .rect)
            }
        }
    }
}
