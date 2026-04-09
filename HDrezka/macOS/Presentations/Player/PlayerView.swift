import AVKit
import Combine
import Defaults
import FactoryKit
import Kingfisher
import MediaPlayer
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

    @FocusState private var isFocused: Bool

    var body: some View {
        let _ = Self._printChanges()
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
                        TopControls(player: player)
                            .opacity(viewModel.isMaskShow ? 1 : 0)
                    }
                    .overlay(alignment: .center) {
                        MiddleControls(player: player)
                            .opacity(viewModel.isMaskShow ? 1 : 0)
                    }
                    .overlay(alignment: .bottom) {
                        BottomControls(player: player)
                            .opacity(viewModel.isMaskShow ? 1 : 0)
                    }
                    .overlay(alignment: .topTrailing) {
                        if let nextTimer = viewModel.nextTimer, viewModel.isSeries, let seasons = viewModel.seasons, let season = viewModel.season, let episode = viewModel.episode {
                            Button {
                                viewModel.nextTrack()
                            } label: {
                                HStack(alignment: .center, spacing: 21) {
                                    VStack(alignment: .leading) {
                                        HStack(alignment: .bottom, spacing: 7) {
                                            Image(systemName: "waveform.circle")
                                                .font(.title2.bold())

                                            Text("key.next")
                                                .font(.title2.bold())
                                        }
                                        .foregroundStyle(Color.accentColor)

                                        Spacer(minLength: 0)

                                        if let nextEpisode = season.episodes.element(after: episode) {
                                            Text("key.season-\(season.name).episode-\(nextEpisode.name)")
                                                .font(.title2.bold())
                                        } else if let nextSeason = seasons.element(after: season), let nextEpisode = nextSeason.episodes.first {
                                            Text("key.season-\(nextSeason.name).episode-\(nextEpisode.name)")
                                                .font(.title2.bold())
                                        }
                                    }

                                    Image(systemName: "play.circle")
                                        .resizable()
                                        .frame(width: 28, height: 28)
                                        .background(Color.accentColor, in: .circle.inset(by: -7).rotation(.degrees(-90)).trim(from: 0.0, to: nextTimer).stroke(style: .init(lineWidth: 6, lineCap: .round, lineJoin: .round)))
                                        .background(.ultraThickMaterial, in: .circle.inset(by: -7).rotation(.degrees(-90)).trim(from: 0.0, to: nextTimer).stroke(style: .init(lineWidth: 8, lineCap: .round, lineJoin: .round)))
                                        .background(Color.accentColor.opacity(0.3), in: .circle.inset(by: -7).rotation(.degrees(-90)).stroke(style: .init(lineWidth: 4, lineCap: .round, lineJoin: .round)))
                                }
                                .frame(height: 50)
                                .padding(.vertical, 16)
                                .padding(.leading, 16)
                                .padding(.trailing, 36)
                                .contentShape(.rect(topLeadingRadius: 6, bottomLeadingRadius: 6))
                                .background(.ultraThickMaterial, in: .rect(topLeadingRadius: 6, bottomLeadingRadius: 6))
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 102)
                            .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                        }
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
//            viewModel.setupPlayer(subtitles: selectPositions.first(where: { position in position.id == voiceActing.voiceId })?.subtitles)
            viewModel.setupPlayer()

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

struct SeekBarView: View {
    private let player: AVPlayer

    init(player: AVPlayer) {
        self.player = player
    }

    @Environment(PlayerViewModel.self) private var viewModel

    var body: some View {
        SliderWithText(value: Binding {
            viewModel.currentTime
        } set: { time in
            player.seek(to: CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), toleranceBefore: .zero, toleranceAfter: .zero) { success in
                if success {
                    viewModel.updateNextTimer()
                }
            }
        }, inRange: 0 ... viewModel.duration, buffers: viewModel.loadedTimeRanges, activeFillColor: .primary, fillColor: .primary.opacity(0.7), emptyColor: .primary.opacity(0.3), height: 8, thumbnails: viewModel.thumbnails) { _ in }
            .frame(height: 25)
            .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
    }
}

struct TopControls: View {
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
    }
}

struct MiddleControls: View {
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
    }
}

struct BottomControls: View {
    private let player: AVPlayer

    init(player: AVPlayer) {
        self.player = player
    }

    @Environment(PlayerViewModel.self) private var viewModel

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading) {
                    HStack(alignment: .center) {
                        if let season = viewModel.season, let episode = viewModel.episode {
                            Text("key.season-\(season.name).episode-\(episode.name)")
                                .font(.title2.bold())
                                .lineLimit(1)
                                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                        }

                        Text(viewModel.voiceActing.name)
                            .font(.title2.bold())
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                    }

                    Text(viewModel.name)
                        .font(.largeTitle.bold())
                        .lineLimit(1)
                        .help(viewModel.name)
                        .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                }

                Spacer()

                HStack(alignment: .center, spacing: 12) {
                    if !viewModel.subtitlesOptions.isEmpty {
                        Menu {
                            Picker("key.subtitles", selection: Binding {
                                viewModel.subtitles
                            } set: { subtitles in
                                viewModel.subtitles = subtitles

                                viewModel.selectSubtitles(subtitles)
                            }) {
                                Text("key.off").tag(nil as String?)

                                ForEach(viewModel.subtitlesOptions, id: \.self) { subtitles in
                                    Text(subtitles.displayName(with: Locale.current)).tag(subtitles.extendedLanguageTag)
                                }
                            }
                            .pickerStyle(.inline)
                        } label: {
                            Image(systemName: "captions.bubble")
                                .font(.title2)
                                .contentShape(.circle)
                        }
                        .buttonStyle(
                            OnPressButtonStyle { isPressed in
                                viewModel.setMask(true, force: isPressed)
                            },
                        )
                        .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                    }

                    Menu {
                        Picker("key.timer", selection: Binding {
                            viewModel.timer
                        } set: {
                            viewModel.timer = $0

                            viewModel.resetTimer()
                        }) {
                            Text("key.off").tag(nil as Int?)

                            ForEach(viewModel.times, id: \.self) { time in
                                let name = switch time {
                                case 900:
                                    String(localized: "key.timer.15m")
                                case 1800:
                                    String(localized: "key.timer.30m")
                                case 2700:
                                    String(localized: "key.timer.45m")
                                case 3600:
                                    String(localized: "key.timer.1h")
                                case -1:
                                    String(localized: "key.timer.end")
                                default:
                                    String(localized: "key.off")
                                }

                                Text(name).tag(time)
                            }
                        }
                        .pickerStyle(.menu)

                        Picker("key.video_gravity", selection: Binding {
                            viewModel.videoGravity
                        } set: {
                            viewModel.playerLayer.videoGravity = $0
                        }) {
                            Text("key.video_gravity.fit").tag(AVLayerVideoGravity.resizeAspect)

                            Text("key.video_gravity.fill").tag(AVLayerVideoGravity.resizeAspectFill)

                            Text("key.video_gravity.stretch").tag(AVLayerVideoGravity.resize)
                        }
                        .pickerStyle(.menu)

                        Picker("key.speed", selection: Binding {
                            viewModel.rate
                        } set: { rate in
                            Defaults[.rate] = rate
                        }) {
                            ForEach(viewModel.rates, id: \.self) { value in
                                Text(verbatim: "\(value)x").tag(value)
                            }
                        }
                        .pickerStyle(.menu)

                        if !viewModel.movie.getAvailableQualities().isEmpty {
                            Picker("key.quality", selection: Binding {
                                viewModel.quality
                            } set: {
                                viewModel.quality = $0

                                let currentSeek = player.currentTime()

                                viewModel.resetPlayer {
                                    viewModel.setupPlayer(seek: currentSeek, isPlaying: viewModel.isPlaying, subtitles: viewModel.subtitles)
                                }
                            }) {
                                ForEach(viewModel.movie.getAvailableQualities(), id: \.self) { value in
                                    Text(value).tag(value)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                            .contentShape(.circle)
                    }
                    .menuStyle(.button)
                    .menuIndicator(.hidden)
                    .buttonStyle(
                        OnPressButtonStyle { isPressed in
                            viewModel.setMask(true, force: isPressed)
                        },
                    )
                    .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                }
            }

            SeekBarView(player: player)
        }
        .padding(.horizontal, 36)
        .padding(.bottom, 36)
    }
}
