import AVKit
import ComposableArchitecture
import SwiftUI

struct PlayerView: View {
    @State private var engine: PlayerEngine
    @State private var store: StoreOf<PlayerFeature>

    init(data: PlayerData) {
        let engine = PlayerEngine()

        _engine = State(initialValue: engine)
        _store = State(initialValue: Store(initialState: PlayerFeature.State(data: data)) { PlayerFeature(engine: engine) })
    }

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss

    @FocusState private var isFocused: Bool

    var body: some View {
        Group {
            if let error = store.error {
                ErrorStateView(error.error) {
                    store.send(.retryTapped)
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 36)
            } else if let player = engine.player {
                CustomAVPlayerView(playerLayer: engine.playerLayer)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(.rect)
                    .gesture(
                        TapGesture(count: 2)
                            .onEnded {
                                guard store.isReady,
                                      let window = Windows.player.window,
                                      !store.isPictureInPictureActive || (store.isPictureInPictureActive && window.styleMask.contains(.fullScreen))
                                else {
                                    return
                                }

                                window.toggleFullScreen(nil)
                            }
                            .exclusively(before:
                                TapGesture(count: 1)
                                    .onEnded {
                                        store.send(.videoTapped)
                                    })
                    )
                    .overlay(alignment: .top) {
                        TopControlsView(player: player)
                    }
                    .overlay(alignment: .center) {
                        MiddleControlsView()
                    }
                    .overlay(alignment: .bottom) {
                        BottomControlsView()
                    }
                    .overlay(alignment: .topTrailing) {
                        NextTimerView()
                    }
                    .background(alignment: .center) {
                        GlowImageView()
                    }
            } else if store.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .environment(store)
        .environment(engine)
        .navigationTitle(Text(verbatim: "Player - \(store.name)"))
        .toolbar(.hidden)
        .frame(minWidth: 900, minHeight: 900 / 16 * 9)
        .ignoresSafeArea()
        .focusable()
        .focused($isFocused)
        .focusEffectDisabled()
        .background(Color.black)
        .preferredColorScheme(.dark)
        .tint(.primary)
        .contentShape(.rect)
        .task {
            store.send(.task)

            if let window = Windows.player.window,
               store.playerFullscreen,
               !window.styleMask.contains(.fullScreen)
            {
                window.toggleFullScreen(nil)
            }

            if store.hideMainWindow,
               let window = Windows.hdrezka.window
            {
                let animation = window.animationBehavior
                window.animationBehavior = .none
                window.orderOut(nil)
                window.animationBehavior = animation
            }
        }
        .onDisappear {
            store.send(.disappeared)

            guard store.hideMainWindow,
                  let window = Windows.hdrezka.window
            else {
                return
            }

            let animation = window.animationBehavior
            window.animationBehavior = .none
            window.orderFront(nil)
            window.animationBehavior = animation
        }
        .onContinuousHover { phase in
            switch phase {
            case .active:
                store.send(.hoverChanged(isActive: true), animation: .easeInOut)
            case .ended:
                store.send(.hoverChanged(isActive: false), animation: .easeInOut)
            }
        }
        .onChange(of: scenePhase) {
            store.send(.scenePhaseChanged(isActive: scenePhase == .active))
        }
        .onChange(of: store.isFocused) {
            isFocused = store.isFocused
        }
        .onChange(of: isFocused) {
            store.isFocused = isFocused
        }
        .onChange(of: store.isDismissed) {
            if store.isDismissed {
                dismiss()
            }
        }
        .onExitCommand {
            store.send(.userActivity)

            guard store.isReady,
                  let window = Windows.player.window,
                  window.styleMask.contains(.fullScreen)
            else {
                return
            }

            window.toggleFullScreen(nil)
        }
        .onMoveCommand { direction in
            switch direction {
            case .up:
                store.send(.moveCommand(.up))
            case .down:
                store.send(.moveCommand(.down))
            case .left:
                store.send(.moveCommand(.left))
            case .right:
                store.send(.moveCommand(.right))
            default:
                store.send(.userActivity)
            }
        }
        .gesture(WindowDragGesture())
        .allowsWindowActivationEvents()
    }
}
