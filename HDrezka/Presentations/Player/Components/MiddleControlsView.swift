import AVKit
import SwiftUI

struct MiddleControlsView: View {
    private let player: AVPlayer

    init(player: AVPlayer) {
        self.player = player
    }

    @Environment(PlayerViewModel.self) private var viewModel

    var body: some View {
        HStack(alignment: .center) {
            if viewModel.isSeries {
                Button {
                    viewModel.prevTrack()
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.title2)
                        .contentShape(.circle)
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.hasPrevoiusEpisode)
                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
            }

            Spacer()

            if viewModel.isLoading {
                ProgressView()
                    .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
            } else {
                Button {
                    viewModel.resetTimer()

                    if !viewModel.isPictureInPictureActive {
                        if viewModel.isPlaying {
                            player.pause()
                        } else {
                            player.playImmediately(atRate: viewModel.rate)
                        }
                    }
                } label: {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.largeTitle)
                        .contentTransition(.symbolEffect(.replace))
                        .contentShape(.circle)
                }
                .buttonStyle(.plain)
                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                .keyboardShortcut(.space, modifiers: [])
            }

            Spacer()

            if viewModel.isSeries {
                Button {
                    viewModel.nextTrack()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                        .contentShape(.circle)
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.hasNextEpisode)
                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
            }
        }
        .frame(width: 160)
        .opacity(viewModel.isMaskShow ? 1 : 0)
    }
}
