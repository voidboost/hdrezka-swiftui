import AVKit
import Combine
import Defaults
import SwiftData
import SwiftUI

struct PlayerView: View {
    @State private var viewModel: PlayerViewModel

    init(data: PlayerData) {
        viewModel = PlayerViewModel(
            poster: data.details.poster,
            name: data.details.nameRussian,
            favs: data.details.favs,
            voiceActing: data.selectedActing,
            hideMainWindow: Defaults[.hideMainWindow],
            seasons: data.seasons,
            season: data.selectedSeason,
            episode: data.selectedEpisode,
            movie: data.movie,
            quality: data.selectedQuality,
        )
    }

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss

    @Environment(AppState.self) private var appState

    @Query private var selectPositions: [SelectPosition]

    @FocusState private var isFocused: Bool

    var body: some View {
        Group {
            if let error = viewModel.error {
                ErrorStateView(error) {
                    viewModel.resetPlayer {
                        viewModel.setupPlayer(subtitles: viewModel.subtitles)
                    }
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 36)
            } else if let player = viewModel.playerLayer.player {
                CustomAVPlayerView(playerLayer: viewModel.playerLayer)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(.rect)
                    .gesture(
                        TapGesture(count: 2)
                            .onEnded {
                                guard player.status == .readyToPlay,
                                      let window = viewModel.window,
                                      !viewModel.isPictureInPictureActive || (viewModel.isPictureInPictureActive && window.styleMask.contains(.fullScreen))
                                else {
                                    return
                                }

                                window.toggleFullScreen(nil)
                            }
                            .exclusively(before:
                                TapGesture(count: 1)
                                    .onEnded {
                                        guard player.status == .readyToPlay,
                                              !viewModel.isPictureInPictureActive,
                                              !viewModel.isLoading
                                        else {
                                            return
                                        }

                                        if viewModel.isPlaying {
                                            player.pause()
                                        } else {
                                            player.playImmediately(atRate: viewModel.rate)
                                        }
                                    }),
                    )
                    .overlay(alignment: .top) {
                        TopControlsView(player: player)
                    }
                    .overlay(alignment: .center) {
                        MiddleControlsView(player: player)
                    }
                    .overlay(alignment: .bottom) {
                        BottomControlsView(player: player)
                    }
                    .overlay(alignment: .topTrailing) {
                        NextTimerView()
                    }
            } else if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(Text(verbatim: "Player - \(viewModel.name)"))
        .toolbar(.hidden)
        .frame(minWidth: 900, minHeight: 900 / 16 * 9)
        .ignoresSafeArea()
        .focusable()
        .focused($isFocused)
        .focusEffectDisabled()
        .background(Color.black)
        .background(WindowAccessor(window: $viewModel.window))
        .preferredColorScheme(.dark)
        .tint(.primary)
        .contentShape(.rect)
        .environment(viewModel)
        .onAppear {
            viewModel.dismiss = dismiss

            viewModel.setupPlayer(subtitles: selectPositions.first(where: { position in position.id == viewModel.voiceActing.voiceId })?.subtitles)

            guard viewModel.hideMainWindow, let window = appState.window else { return }

            let animation = window.animationBehavior
            window.animationBehavior = .none
            window.orderOut(nil)
            window.animationBehavior = animation
        }
        .onDisappear {
            viewModel.resetPlayer()

            guard viewModel.hideMainWindow, let window = appState.window else { return }

            let animation = window.animationBehavior
            window.animationBehavior = .none
            window.orderFront(nil)
            window.animationBehavior = animation
        }
        .onContinuousHover { phase in
            viewModel.resetTimer()

            switch phase {
            case .active:
                viewModel.showCursor()

                viewModel.setMask(!viewModel.isPictureInPictureActive)
            case .ended:
                viewModel.showCursor()

                viewModel.setMask((viewModel.isLoading || !viewModel.isPlaying) && !viewModel.isPictureInPictureActive)
            }
        }
        .onChange(of: viewModel.window) {
            guard let window = viewModel.window,
                  viewModel.playerFullscreen,
                  !window.styleMask.contains(.fullScreen)
            else {
                return
            }

            window.toggleFullScreen(nil)
        }
        .onChange(of: scenePhase) {
            guard let player = viewModel.playerLayer.player,
                  player.status == .readyToPlay
            else {
                return
            }

            switch scenePhase {
            case .active:
                break
            default:
                if !viewModel.isPictureInPictureActive, viewModel.isPlaying {
                    player.pause()
                }
            }
        }
        .onChange(of: viewModel.spatialAudio) {
            guard let player = viewModel.playerLayer.player,
                  player.status == .readyToPlay,
                  let currentItem = player.currentItem
            else {
                return
            }

            currentItem.allowedAudioSpatializationFormats = viewModel.spatialAudio.format
        }
        .onChange(of: viewModel.isFocused) {
            isFocused = viewModel.isFocused
        }
        .onChange(of: isFocused) {
            viewModel.isFocused = isFocused
        }
        .onExitCommand {
            viewModel.resetTimer()

            guard let player = viewModel.playerLayer.player,
                  player.status == .readyToPlay,
                  let window = viewModel.window,
                  window.styleMask.contains(.fullScreen)
            else {
                return
            }

            window.toggleFullScreen(nil)
        }
        .onMoveCommand { direction in
            viewModel.resetTimer()

            guard let player = viewModel.playerLayer.player,
                  player.status == .readyToPlay,
                  !viewModel.isPictureInPictureActive
            else {
                return
            }

            switch direction {
            case .up:
                guard player.volume < 1.0 else { return }

                player.volume = min(player.volume + 0.05, 1.0)
            case .down:
                guard player.volume > 0.0 else { return }

                player.volume = max(player.volume - 0.05, 0.0)
            case .left:
                player.seek(to: CMTime(seconds: max(viewModel.currentTime - 10.0, 0.0), preferredTimescale: CMTimeScale(NSEC_PER_SEC)), toleranceBefore: .zero, toleranceAfter: .zero) { complete in
                    if viewModel.isPlaying, complete {
                        player.playImmediately(atRate: viewModel.rate)
                    }
                }

                viewModel.currentTime = max(viewModel.currentTime - 10.0, 0.0)
            case .right:
                player.seek(to: CMTime(seconds: min(viewModel.currentTime + 10.0, viewModel.duration), preferredTimescale: CMTimeScale(NSEC_PER_SEC)), toleranceBefore: .zero, toleranceAfter: .zero) { complete in
                    if viewModel.isPlaying, complete {
                        player.playImmediately(atRate: viewModel.rate)
                    }
                }

                viewModel.currentTime = min(viewModel.currentTime + 10.0, viewModel.duration)
            default:
                break
            }
        }
        .gesture(WindowDragGesture())
        .allowsWindowActivationEvents()
    }
}
