import AVKit
import SwiftUI

struct SeekBarView: View {
    private let player: AVPlayer

    init(player: AVPlayer) {
        self.player = player
    }

    @Environment(PlayerViewModel.self) private var viewModel

    var body: some View {
        SliderWithTextView(value: Binding {
            viewModel.currentTime
        } set: { time in
            viewModel.seek(player, to: time)
        }, inRange: 0 ... viewModel.duration, buffers: viewModel.loadedTimeRanges, activeFillColor: .primary, fillColor: .primary.opacity(0.7), emptyColor: .primary.opacity(0.3), height: 8, thumbnails: viewModel.thumbnails) { _ in }
            .frame(height: 25)
            .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
    }
}
