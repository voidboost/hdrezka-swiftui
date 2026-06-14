import AVKit
import SwiftUI

struct CustomAVPlayerView: NSViewRepresentable {
    var playerLayer: AVPlayerLayer

    func makeNSView(context _: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true

        playerLayer.frame = view.bounds
        playerLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]

        view.layer?.addSublayer(playerLayer)

        return view
    }

    func updateNSView(_ nsView: NSView, context _: Context) {
        playerLayer.frame = nsView.bounds
    }
}
