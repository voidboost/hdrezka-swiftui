import AVKit
import ComposableArchitecture
import SwiftUI

struct MiddleControlsView: View {
    @Environment(StoreOf<PlayerFeature>.self) private var store

    var body: some View {
        HStack(alignment: .center) {
            if store.isSeries {
                Button {
                    store.send(.previousTrackTapped, animation: .easeInOut(duration: 0.15))
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.title2)
                        .contentShape(.circle)
                }
                .buttonStyle(.plain)
                .disabled(!store.hasPreviousEpisode)
                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
            }

            Spacer()

            if store.isLoading {
                ProgressView()
                    .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
            } else {
                Button {
                    store.send(.playPauseTapped)
                } label: {
                    Image(systemName: store.isPlaying ? "pause.fill" : "play.fill")
                        .font(.largeTitle)
                        .contentTransition(.symbolEffect(.replace))
                        .contentShape(.circle)
                }
                .buttonStyle(.plain)
                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                .keyboardShortcut(.space, modifiers: [])
            }

            Spacer()

            if store.isSeries {
                Button {
                    store.send(.nextTrackTapped, animation: .easeInOut(duration: 0.15))
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                        .contentShape(.circle)
                }
                .buttonStyle(.plain)
                .disabled(!store.hasNextEpisode)
                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
            }
        }
        .frame(width: 160)
        .opacity(store.isMaskShow ? 1 : 0)
        .animation(.easeInOut, value: store.isMaskShow)
    }
}
