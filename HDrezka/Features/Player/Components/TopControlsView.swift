import AVKit
import ComposableArchitecture
import SwiftUI

struct TopControlsView: View {
    private let player: AVPlayer

    init(player: AVPlayer) {
        self.player = player
    }

    @Environment(StoreOf<PlayerFeature>.self) private var store
    @Environment(PlayerEngine.self) private var engine

    var body: some View {
        HStack(alignment: .center) {
            if engine.pipController != nil, AVPictureInPictureController.isPictureInPictureSupported() {
                Button {
                    store.send(.pictureInPictureTapped)
                } label: {
                    Image(systemName: "pip.enter")
                        .font(.title2)
                        .contentShape(.circle)
                }
                .buttonStyle(.plain)
                .disabled(store.isPictureInPictureActive || !store.isPictureInPicturePossible)
                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
            }

            if store.routesDetected {
                AirPlayButtonView(player: player) { isPressed in
                    if isPressed {
                        store.send(.lockMask(true), animation: .easeInOut)
                    } else {
                        store.send(.unlockMask(true), animation: .easeInOut)
                    }
                }
                .frame(width: 35, height: 35)
                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
            }

            Spacer()

            SliderWithoutTextView(value: Binding {
                store.volume
            } set: { volume in
                store.send(.volumeChanged(volume))
            }, inRange: 0 ... 1, activeFillColor: .primary, fillColor: .primary.opacity(0.7), emptyColor: .primary.opacity(0.3), height: 8)
                .frame(width: 120, height: 10)
                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)

            VStack(alignment: .center) {
                Button {
                    store.send(.toggleMuteTapped)
                } label: {
                    Image(systemName: store.isMuted ? "speaker.slash.fill" : "speaker.wave.3.fill", variableValue: Double(store.volume))
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
        .opacity(store.isMaskShow ? 1 : 0)
        .animation(.easeInOut, value: store.isMaskShow)
    }
}
