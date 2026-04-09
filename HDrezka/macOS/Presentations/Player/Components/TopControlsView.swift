import AVKit
import SwiftUI

struct TopControlsView: View {
    private let player: AVPlayer

    init(player: AVPlayer) {
        self.player = player
    }

    @Environment(PlayerViewModel.self) private var viewModel

    var body: some View {
        HStack(alignment: .center) {
            if let pipController = viewModel.pipController, AVPictureInPictureController.isPictureInPictureSupported() {
                Button {
                    pipController.startPictureInPicture()
                } label: {
                    Image(systemName: "pip.enter")
                        .font(.title2)
                        .contentShape(.circle)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isPictureInPictureActive || !viewModel.isPictureInPicturePossible)
                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
            }

            Spacer()

            SliderWithoutText(value: Binding {
                viewModel.volume
            } set: { volume in
                player.volume = volume
            }, inRange: 0 ... 1, activeFillColor: .primary, fillColor: .primary.opacity(0.7), emptyColor: .primary.opacity(0.3), height: 8)
                .frame(width: 120, height: 10)
                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)

            VStack(alignment: .center) {
                Button {
                    viewModel.resetTimer()

                    if !viewModel.isPictureInPictureActive {
                        player.isMuted.toggle()
                    }
                } label: {
                    Image(systemName: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.3.fill", variableValue: Double(viewModel.volume))
                        .font(.title2)
                        .contentTransition(.symbolEffect(.replace))
                        .contentShape(.circle)
                }
                .buttonStyle(.plain)
                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                .keyboardShortcut(.init("m"), modifiers: [])
            }
            .frame(width: 30, height: 30)
        }
        .padding(.top, 36)
        .padding(.horizontal, 36)
        .opacity(viewModel.isMaskShow ? 1 : 0)
    }
}
