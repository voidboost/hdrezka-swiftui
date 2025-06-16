import AVKit
import Combine
import CoreData
import Defaults
import FactoryKit
import MediaPlayer
import SwiftUI

struct PlayerView: View {
    @Injected(\.session) private var session
    @Injected(\.saveWatchingStateUseCase) private var saveWatchingStateUseCase
    @Injected(\.getMovieThumbnailsUseCase) private var getMovieThumbnailsUseCase
    @Injected(\.getMovieVideoUseCase) private var getMovieVideoUseCase

    @Default(.isLoggedIn) private var isLoggedIn
    @Default(.playerFullscreen) private var playerFullscreen
    @Default(.spatialAudio) private var spatialAudio
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject private var appState: AppState

    @FetchRequest(fetchRequest: PlayerPosition.fetch()) private var playerPositions: FetchedResults<PlayerPosition>
    @FetchRequest(fetchRequest: SelectPosition.fetch()) private var selectPositions: FetchedResults<SelectPosition>

    @State private var subscriptions: Set<AnyCancellable> = []

    private let poster: String
    private let name: String
    private let favs: String
    private let voiceActing: MovieVoiceActing

    private let hideMainWindow: Bool

    private let times: [Int]

    @State private var seasons: [MovieSeason]?
    @State private var season: MovieSeason?
    @State private var episode: MovieEpisode?
    @State private var movie: MovieVideo
    @State private var quality: String

    private let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    private let remoteCommandCenter = MPRemoteCommandCenter.shared()

    private let playerLayer: AVPlayerLayer = .init()
    @State private var pipController: AVPictureInPictureController?
    @State private var isPictureInPictureActive: Bool = false
    @State private var isPictureInPicturePossible: Bool = false
    @State private var videoGravity: AVLayerVideoGravity = .resizeAspect
    @State private var loadedTimeRanges: [CMTimeRange] = []
    @State private var timeObserverToken: Any?
    private let rates: [Float] = [0.5, 1.0, 1.25, 1.5, 2.0]
    @State private var timer: Int?
    @State private var timerWork: DispatchWorkItem?
    @State private var nextTimer: CGFloat?
    @State private var rate: Float = 1.0
    @State private var currentTime: Double = 0.0
    @State private var duration: Double = .greatestFiniteMagnitude
    @State private var volume: Float = 1.0
    @State private var error: Error?
    @State private var subtitles: String?
    @State private var isPlaying: Bool = true
    @State private var isLoading: Bool = true
    @State private var isMuted: Bool = false
    @State private var isMaskShow: Bool = true
    @State private var delayHide: DispatchWorkItem?
    @State private var subtitlesOptions: [AVMediaSelectionOption] = []
    @State private var thumbnails: WebVTT?
    @State private var window: NSWindow?

    init(data: PlayerData) {
        poster = data.details.poster
        name = data.details.nameRussian
        favs = data.details.favs
        voiceActing = data.selectedActing

        seasons = data.seasons
        season = data.selectedSeason
        episode = data.selectedEpisode
        movie = data.movie
        quality = data.selectedQuality

        times = data.details.series != nil ? [900, 1800, 2700, 3600, -1] : [900, 1800, 2700, 3600]

        hideMainWindow = Defaults[.hideMainWindow]
    }

    var body: some View {
        ZStack(alignment: .center) {
            if let error {
                ErrorStateView(error) {
                    resetPlayer {
                        setupPlayer(isMuted: isMuted, subtitles: subtitles, volume: volume)
                    }
                }
                .padding(.vertical, 52)
                .padding(.horizontal, 36)
            } else if let player = playerLayer.player {
                CustomAVPlayerView(playerLayer: playerLayer)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack(alignment: .center) {
                    VStack {
                        HStack(alignment: .center) {
                            if let pipController, AVPictureInPictureController.isPictureInPictureSupported() {
                                Button {
                                    pipController.startPictureInPicture()
                                } label: {
                                    Image(systemName: "pip.enter")
                                        .font(.system(size: 17))
                                }
                                .buttonStyle(.plain)
                                .disabled(isPictureInPictureActive || !isPictureInPicturePossible)
                                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                            }

                            Spacer()

                            HStack(alignment: .center) {
                                SliderWithoutText(value: Binding {
                                    volume
                                } set: { volume in
                                    player.volume = volume
                                }, inRange: 0 ... 1, activeFillColor: .primary, fillColor: .primary.opacity(0.7), emptyColor: .primary.opacity(0.3), height: 8) { onEditingChanged in
                                    if onEditingChanged, isMuted {
                                        player.isMuted.toggle()
                                    }
                                }
                                .frame(width: 120, height: 10)
                                .onHover { hovering in
                                    guard let window else { return }

                                    window.isMovableByWindowBackground = !hovering
                                }
                                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)

                                VStack(alignment: .center) {
                                    Button {
                                        resetTimer()

                                        if !isPictureInPictureActive {
                                            player.isMuted.toggle()
                                        }
                                    } label: {
                                        Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.3.fill", variableValue: Double(volume))
                                            .font(.system(size: 17))
                                            .viewModifier { view in
                                                if #available(macOS 14, *) {
                                                    view.contentTransition(.symbolEffect(.replace))
                                                } else {
                                                    view
                                                }
                                            }
                                    }
                                    .buttonStyle(.plain)
                                    .keyboardShortcut("m", modifiers: [])
                                    .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                                }
                                .frame(width: 30)
                            }
                            .frame(height: 30)
                        }

                        Spacer()
                    }

                    VStack {
                        Spacer()

                        HStack(alignment: .center) {
                            if let seasons, let season, let episode {
                                Button {
                                    prevTrack(seasons, season, episode)
                                } label: {
                                    Image(systemName: "backward.fill")
                                        .font(.system(size: 18))
                                }
                                .buttonStyle(.plain)
                                .disabled(seasons.element(before: season) == nil && season.episodes.element(before: episode) == nil)
                                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                            }

                            Spacer()

                            if isLoading {
                                ProgressView()
                                    .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                            } else {
                                Button {
                                    resetTimer()

                                    if !isPictureInPictureActive {
                                        if isPlaying {
                                            player.pause()
                                        } else {
                                            player.playImmediately(atRate: rate)
                                        }
                                    }
                                } label: {
                                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 43))
                                        .viewModifier { view in
                                            if #available(macOS 14, *) {
                                                view.contentTransition(.symbolEffect(.replace))
                                            } else {
                                                view
                                            }
                                        }
                                }
                                .buttonStyle(.plain)
                                .keyboardShortcut(.space, modifiers: [])
                                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                            }

                            Spacer()

                            if let seasons, let season, let episode {
                                Button {
                                    nextTrack(seasons, season, episode)
                                } label: {
                                    Image(systemName: "forward.fill")
                                        .font(.system(size: 18))
                                }
                                .buttonStyle(.plain)
                                .disabled(seasons.element(after: season) == nil && season.episodes.element(after: episode) == nil)
                                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                            }
                        }
                        .frame(width: 160)

                        Spacer()
                    }

                    VStack {
                        Spacer()

                        VStack(alignment: .center, spacing: 8) {
                            HStack(alignment: .bottom) {
                                VStack(alignment: .leading) {
                                    HStack(alignment: .center) {
                                        if let season, let episode {
                                            Text("key.season-\(season.name).episode-\(episode.name)")
                                                .font(.title2.bold())
                                                .lineLimit(1)
                                                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                                        }

                                        Text(voiceActing.name)
                                            .font(.title2.bold())
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                            .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                                    }

                                    Text(name)
                                        .font(.largeTitle.bold())
                                        .lineLimit(1)
                                        .help(name)
                                        .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                                }

                                Spacer()

                                HStack(alignment: .center) {
                                    Button {
                                        withAnimation(.easeInOut) {
                                            if videoGravity == .resizeAspect {
                                                playerLayer.videoGravity = .resizeAspectFill
                                            } else {
                                                playerLayer.videoGravity = .resizeAspect
                                            }
                                        }
                                    } label: {
                                        Label("key.video_gravity", systemImage: videoGravity == .resizeAspect ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left")
                                            .labelStyle(.iconOnly)
                                            .font(.system(size: 17))
                                            .viewModifier { view in
                                                if #available(macOS 14, *) {
                                                    view.contentTransition(.symbolEffect(.replace))
                                                } else {
                                                    view
                                                }
                                            }
                                    }
                                    .buttonStyle(.plain)
                                    .shadow(color: .black.opacity(0.5), radius: 4, y: 2)

                                    if !subtitlesOptions.isEmpty {
                                        Menu {
                                            Picker(selection: Binding {
                                                subtitles
                                            } set: { subtitles in
                                                self.subtitles = subtitles

                                                selectSubtitles(subtitles)
                                            }) {
                                                Text("key.off").tag(nil as String?)

                                                ForEach(subtitlesOptions, id: \.self) { subtitles in
                                                    Text(subtitles.displayName(with: Locale.current)).tag(subtitles.extendedLanguageTag)
                                                }
                                            } label: {
                                                EmptyView()
                                            }
                                            .pickerStyle(.inline)
                                        } label: {
                                            Label("key.subtitles", systemImage: "captions.bubble")
                                                .labelStyle(.iconOnly)
                                                .font(.system(size: 17))
                                        }
                                        .buttonStyle(.plain)
                                        .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                                    }

                                    Menu {
                                        Menu {
                                            Picker(selection: Binding {
                                                timer
                                            } set: {
                                                timer = $0

                                                resetTimer()
                                            }) {
                                                Text("key.off").tag(nil as Int?)

                                                ForEach(times, id: \.self) { time in
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
                                            } label: {
                                                EmptyView()
                                            }
                                            .pickerStyle(.inline)
                                        } label: {
                                            Label("key.timer", systemImage: "timer")
                                                .labelStyle(.titleOnly)
                                                .font(.system(size: 17))
                                        }
                                        .buttonStyle(.plain)

                                        Menu {
                                            Picker(selection: Binding {
                                                rate
                                            } set: { rate in
                                                self.rate = rate
                                                nowPlayingInfoCenter.nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = rate

                                                if isPlaying {
                                                    player.playImmediately(atRate: rate)
                                                }
                                            }) {
                                                ForEach(rates, id: \.self) { value in
                                                    Text(verbatim: "\(value.description)x").tag(value)
                                                }
                                            } label: {
                                                EmptyView()
                                            }
                                            .pickerStyle(.inline)
                                        } label: {
                                            Label("key.speed", systemImage: "gauge.with.dots.needle.33percent")
                                                .labelStyle(.titleOnly)
                                                .font(.system(size: 17))
                                        }
                                        .buttonStyle(.plain)

                                        if !movie.getAvailableQualities().isEmpty {
                                            Menu {
                                                Picker(selection: Binding {
                                                    quality
                                                } set: {
                                                    quality = $0

                                                    let currentSeek = player.currentTime()

                                                    resetPlayer {
                                                        setupPlayer(seek: currentSeek, isPlaying: isPlaying, isMuted: isMuted, subtitles: subtitles, volume: volume)
                                                    }
                                                }) {
                                                    ForEach(movie.getAvailableQualities(), id: \.self) { value in
                                                        Text(value).tag(value)
                                                    }
                                                } label: {
                                                    EmptyView()
                                                }
                                                .pickerStyle(.inline)
                                            } label: {
                                                Label("key.quality", systemImage: "gearshape")
                                                    .labelStyle(.titleOnly)
                                                    .font(.system(size: 17))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    } label: {
                                        Label("key.settings", systemImage: "ellipsis.circle")
                                            .labelStyle(.iconOnly)
                                            .font(.system(size: 17))
                                    }
                                    .buttonStyle(.plain)
                                    .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                                }
                            }

                            SliderWithText(value: Binding {
                                currentTime
                            } set: { time in
                                player.seek(to: CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), toleranceBefore: .zero, toleranceAfter: .zero) { success in
                                    if success {
                                        updateNextTimer()
                                    }
                                }
                            }, inRange: 0 ... duration, buffers: loadedTimeRanges, activeFillColor: .primary, fillColor: .primary.opacity(0.7), emptyColor: .primary.opacity(0.3), height: 6, thumbnails: thumbnails) { _ in }
                                .frame(height: 23)
                                .onHover { hovering in
                                    guard let window else { return }

                                    window.isMovableByWindowBackground = !hovering
                                }
                                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                        }
                    }
                }
                .padding(36)
                .opacity(isMaskShow ? 1 : 0)

                if let nextTimer, let seasons, let season, let episode {
                    VStack(alignment: .trailing) {
                        HStack {
                            Spacer(minLength: 0)

                            Button {
                                nextTrack(seasons, season, episode)
                            } label: {
                                HStack(alignment: .center, spacing: 21) {
                                    VStack(alignment: .leading) {
                                        HStack(alignment: .bottom, spacing: 7) {
                                            if let image = NSImage(named: "Bars") {
                                                Image(nsImage: image.resized(to: CGSize(width: 15, height: 14)))
                                                    .offset(y: -14.0 / 4)
                                            } else {
                                                Image(systemName: "chart.bar.xaxis")
                                                    .font(.system(size: 15))
                                            }

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
                                .background(.ultraThinMaterial)
                                .clipShape(.rect(topLeadingRadius: 6, bottomLeadingRadius: 6))
                                .contentShape(.rect(topLeadingRadius: 6, bottomLeadingRadius: 6))
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.top, 102)
                    .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                }
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(Text(verbatim: "Player - \(name)"))
        .padding(1)
        .task {
            setupPlayer(subtitles: selectPositions.first(where: { position in position.id == voiceActing.voiceId })?.subtitles)

            if hideMainWindow, let window = appState.window {
                let animation = window.animationBehavior
                window.animationBehavior = .none
                window.orderOut(nil)
                window.animationBehavior = animation
            }
        }
        .onDisappear {
            resetPlayer()

            if hideMainWindow, let window = appState.window {
                let animation = window.animationBehavior
                window.animationBehavior = .none
                window.orderFront(nil)
                window.animationBehavior = animation
            }
        }
        .onContinuousHover { phase in
            resetTimer()

            switch phase {
            case .active:
                showCursor()

                setMask(!isPictureInPictureActive)
            case .ended:
                showCursor()

                setMask((isLoading || !isPlaying) && !isPictureInPictureActive)
            }
        }
        .customOnChange(of: scenePhase) {
            guard let player = playerLayer.player,
                  player.status == .readyToPlay
            else {
                return
            }

            switch scenePhase {
            case .active:
                break
            default:
                if !isPictureInPictureActive, isPlaying {
                    player.pause()
                }
            }
        }
        .customOnChange(of: spatialAudio) {
            guard let player = playerLayer.player,
                  player.status == .readyToPlay,
                  let currentItem = player.currentItem
            else {
                return
            }

            currentItem.allowedAudioSpatializationFormats = spatialAudio.format
        }
        .ignoresSafeArea()
        .focusable()
        .viewModifier { view in
            if #available(macOS 14, *) {
                view.focusEffectDisabled()
            } else {
                view
            }
        }
        .frame(minWidth: 900, minHeight: 900 / 16 * 9)
        .background(WindowAccessor { window in
            self.window = window

            window.isMovableByWindowBackground = true

            if #unavailable(macOS 14) {
                window.contentView?.focusRingType = .none
            }

            if playerFullscreen,
               !window.styleMask.contains(.fullScreen)
            {
                window.toggleFullScreen(nil)
            }
        })
        .preferredColorScheme(.dark)
        .tint(.primary)
        .background(Color.black)
        .contentShape(.rect)
        .toolbar(.hidden)
        .onExitCommand {
            resetTimer()

            guard let player = playerLayer.player,
                  player.status == .readyToPlay,
                  let window,
                  window.styleMask.contains(.fullScreen)
            else {
                return
            }

            window.toggleFullScreen(nil)
        }
        .onMoveCommand { direction in
            resetTimer()

            guard let player = playerLayer.player,
                  player.status == .readyToPlay,
                  !isPictureInPictureActive
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
                player.seek(to: CMTime(seconds: max(currentTime - 10.0, 0.0), preferredTimescale: CMTimeScale(NSEC_PER_SEC)), toleranceBefore: .zero, toleranceAfter: .zero) { complete in
                    if isPlaying, complete {
                        player.playImmediately(atRate: rate)
                    }
                }

                currentTime = max(currentTime - 10.0, 0.0)
            case .right:
                player.seek(to: CMTime(seconds: min(currentTime + 10.0, duration), preferredTimescale: CMTimeScale(NSEC_PER_SEC)), toleranceBefore: .zero, toleranceAfter: .zero) { complete in
                    if isPlaying, complete {
                        player.playImmediately(atRate: rate)
                    }
                }

                currentTime = min(currentTime + 10.0, duration)
            default:
                break
            }
        }
        .gesture(
            DragGesture()
                .exclusively(before:
                    TapGesture(count: 2)
                        .onEnded {
                            guard let player = playerLayer.player,
                                  player.status == .readyToPlay,
                                  let window,
                                  !isPictureInPictureActive || (isPictureInPictureActive && window.styleMask.contains(.fullScreen))
                            else {
                                return
                            }

                            window.toggleFullScreen(nil)
                        }
                        .exclusively(before:
                            TapGesture(count: 1)
                                .onEnded {
                                    guard let player = playerLayer.player,
                                          player.status == .readyToPlay,
                                          !isPictureInPictureActive,
                                          !isLoading
                                    else {
                                        return
                                    }

                                    if isPlaying {
                                        player.pause()
                                    } else {
                                        player.playImmediately(atRate: rate)
                                    }
                                })),
        )
    }

    private func setupPlayer(seek: CMTime? = nil, isPlaying playing: Bool = true, isMuted muted: Bool = false, subtitles: String? = nil, volume vol: Float = 1.0) {
        guard let link = movie.getClosestTo(quality: quality),
              let url = URL(string: "\(link.absoluteString):hls:manifest.m3u8")
        else {
            return
        }

        let player = CustomAVPlayer(m3u8: url, subtitles: movie.subtitles)

        if let player, let currentItem = player.currentItem {
            let pipController = AVPictureInPictureController(playerLayer: playerLayer)

            playerLayer.videoGravity = videoGravity

            nowPlayingInfoCenter.nowPlayingInfo = [:]

            if let thumbnails = movie.thumbnails {
                getMovieThumbnailsUseCase(path: thumbnails)
                    .receive(on: DispatchQueue.main)
                    .sink { _ in } receiveValue: { thumbnails in
                        self.thumbnails = thumbnails
                    }
                    .store(in: &subscriptions)
            }

            timeObserverToken = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: .main) { time in
                let currentTime = time.seconds

                self.currentTime = currentTime

                nowPlayingInfoCenter.nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
                nowPlayingInfoCenter.nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = rate
                nowPlayingInfoCenter.nowPlayingInfo?[MPNowPlayingInfoPropertyCurrentPlaybackDate] = currentItem.currentDate()
                nowPlayingInfoCenter.nowPlayingInfo?[MPNowPlayingInfoPropertyDefaultPlaybackRate] = player.defaultRate

                if let position = playerPositions.first(where: { position in
                    position.id == voiceActing.voiceId &&
                        position.acting == voiceActing.translatorId &&
                        position.season == season?.seasonId &&
                        position.episode == episode?.episodeId
                }) {
                    position.position = currentTime

                    position.managedObjectContext?.saveContext()
                } else {
                    let position = PlayerPosition(context: viewContext)
                    position.id = voiceActing.voiceId
                    position.acting = voiceActing.translatorId
                    position.season = season?.seasonId
                    position.episode = episode?.episodeId
                    position.position = currentTime

                    viewContext.saveContext()
                }

                updateNextTimer()
            }

            player.publisher(for: \.status)
                .receive(on: DispatchQueue.main)
                .sink { status in
                    switch status {
                    case .readyToPlay:
                        currentItem.asset.loadMediaSelectionGroup(for: .legible) { mediaSelectionGroup, _ in
                            if let mediaSelectionGroup {
                                currentItem.select(mediaSelectionGroup.options.filter { $0.extendedLanguageTag != nil }.first(where: { $0.extendedLanguageTag == subtitles }), in: mediaSelectionGroup)

                                withAnimation(.easeInOut(duration: 0.15)) {
                                    subtitlesOptions = mediaSelectionGroup.options.filter { $0.extendedLanguageTag != nil }
                                }

                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                    self.subtitles = subtitles
                                }
                            }
                        }

                        if let seasons, let season, let episode {
                            remoteCommandCenter.previousTrackCommand.addTarget { _ in
                                prevTrack(seasons, season, episode)

                                return .success
                            }

                            remoteCommandCenter.nextTrackCommand.addTarget { _ in
                                nextTrack(seasons, season, episode)

                                return .success
                            }

                            remoteCommandCenter.previousTrackCommand.isEnabled = seasons.element(before: season) != nil || season.episodes.element(before: episode) != nil
                            remoteCommandCenter.nextTrackCommand.isEnabled = seasons.element(after: season) != nil || season.episodes.element(after: episode) != nil
                        }

                        updateNextTimer()

                        if let seek {
                            player.seek(to: seek, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
                                if playing {
                                    player.playImmediately(atRate: rate)
                                }
                            }
                        } else {
                            if let position = playerPositions.first(where: { position in
                                position.id == voiceActing.voiceId &&
                                    position.acting == voiceActing.translatorId &&
                                    position.season == season?.seasonId &&
                                    position.episode == episode?.episodeId
                            }) {
                                player.seek(to: CMTime(seconds: position.position, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), toleranceBefore: .zero, toleranceAfter: .zero) { _ in
                                    if playing {
                                        player.playImmediately(atRate: rate)
                                    }
                                }
                            } else if playing {
                                player.playImmediately(atRate: rate)
                            }
                        }
                    default:
                        break
                    }
                }
                .store(in: &subscriptions)

            player.publisher(for: \.timeControlStatus)
                .receive(on: DispatchQueue.main)
                .sink { status in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        switch status {
                        case .playing:
                            isPlaying = true
                            isLoading = false

                            nowPlayingInfoCenter.playbackState = .playing
                        case .paused:
                            isPlaying = false
                            isLoading = false

                            nowPlayingInfoCenter.playbackState = .paused
                        case .waitingToPlayAtSpecifiedRate:
                            isPlaying = false
                            isLoading = true

                            nowPlayingInfoCenter.playbackState = .paused
                        default:
                            isPlaying = false
                            isLoading = true

                            nowPlayingInfoCenter.playbackState = .paused
                        }
                    }

                    showCursor()

                    setMask(!isPictureInPictureActive)

                    updateNextTimer()
                }
                .store(in: &subscriptions)

            player.publisher(for: \.isMuted)
                .receive(on: DispatchQueue.main)
                .sink { isMuted in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        self.isMuted = isMuted
                    }

                    showCursor()

                    setMask(!isPictureInPictureActive)

                    updateNextTimer()
                }
                .store(in: &subscriptions)

            player.publisher(for: \.volume)
                .receive(on: DispatchQueue.main)
                .sink { volume in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        self.volume = volume
                    }

                    showCursor()

                    setMask(!isPictureInPictureActive)

                    updateNextTimer()
                }
                .store(in: &subscriptions)

            player.publisher(for: \.error)
                .compactMap(\.self)
                .handleError()
                .receive(on: DispatchQueue.main)
                .sink { error in
                    resetPlayer {
                        withAnimation(.easeInOut) {
                            self.error = error
                        }
                    }
                }
                .store(in: &subscriptions)

            currentItem.publisher(for: \.duration)
                .compactMap(\.self)
                .filter { $0.isValid && !$0.isIndefinite && !$0.isNegativeInfinity && !$0.isPositiveInfinity && $0.seconds > 0 }
                .receive(on: DispatchQueue.main)
                .sink { duration in
                    self.duration = duration.seconds

                    nowPlayingInfoCenter.nowPlayingInfo?[MPMediaItemPropertyPlaybackDuration] = duration.seconds

                    updateNextTimer()
                }
                .store(in: &subscriptions)

            currentItem.publisher(for: \.loadedTimeRanges)
                .compactMap { $0 as? [CMTimeRange] }
                .receive(on: DispatchQueue.main)
                .sink { loadedTimeRanges in
                    self.loadedTimeRanges = loadedTimeRanges
                }
                .store(in: &subscriptions)

            currentItem.publisher(for: \.error)
                .compactMap(\.self)
                .handleError()
                .receive(on: DispatchQueue.main)
                .sink { error in
                    resetPlayer {
                        withAnimation(.easeInOut) {
                            self.error = error
                        }
                    }
                }
                .store(in: &subscriptions)

            NotificationCenter.default.publisher(for: AVPlayerItem.didPlayToEndTimeNotification, object: currentItem)
                .receive(on: DispatchQueue.main)
                .sink { _ in
                    player.seek(to: CMTime(seconds: 0, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), toleranceBefore: .zero, toleranceAfter: .zero) { _ in
                        if isPictureInPictureActive, let pipController {
                            pipController.stopPictureInPicture()
                        } else if timer != -1, let seasons, let season, let episode {
                            nextTrack(seasons, season, episode)
                        }

                        updateNextTimer()
                    }
                }
                .store(in: &subscriptions)

            NotificationCenter.default.publisher(for: AVPlayerItem.failedToPlayToEndTimeNotification, object: currentItem)
                .compactMap { $0.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error }
                .handleError()
                .receive(on: DispatchQueue.main)
                .sink { error in
                    resetPlayer {
                        withAnimation(.easeInOut) {
                            self.error = error
                        }
                    }
                }
                .store(in: &subscriptions)

//            NotificationCenter.default.publisher(for: AVPlayerItem.newErrorLogEntryNotification, object: currentItem)
//                .compactMap { ($0.object as? AVPlayerItem)?.errorLog()?.events.last }
//                .receive(on: DispatchQueue.main)
//                .sink { error in
//                    resetPlayer {
//                        withAnimation(.easeInOut) {
//                            self.error = HDrezkaErrorplayer(error.errorComment ?? "")
//                        }
//                    }
//                }
//                .store(in: &subscriptions)

            playerLayer.publisher(for: \.videoGravity)
                .receive(on: DispatchQueue.main)
                .sink { videoGravity in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        self.videoGravity = videoGravity
                    }
                }
                .store(in: &subscriptions)

            if let pipController {
                pipController.publisher(for: \.isPictureInPictureActive)
                    .receive(on: DispatchQueue.main)
                    .sink { isPictureInPictureActive in
                        withAnimation(.easeInOut) {
                            self.isPictureInPictureActive = isPictureInPictureActive
                        }

                        showCursor()

                        setMask(!isPictureInPictureActive)

                        updateNextTimer()

//                        if let window {
//                            if isPictureInPictureActive {
//                                window.miniaturize(nil)
//                            } else {
//                                window.deminiaturize(nil)
//                            }
//                        }
                    }
                    .store(in: &subscriptions)

                pipController.publisher(for: \.isPictureInPicturePossible)
                    .receive(on: DispatchQueue.main)
                    .sink { isPictureInPicturePossible in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            self.isPictureInPicturePossible = isPictureInPicturePossible
                        }
                    }
                    .store(in: &subscriptions)
            }

            nowPlayingInfoCenter.nowPlayingInfo?[MPNowPlayingInfoPropertyAssetURL] = url
            nowPlayingInfoCenter.nowPlayingInfo?[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.video.rawValue
            nowPlayingInfoCenter.nowPlayingInfo?[MPNowPlayingInfoPropertyIsLiveStream] = false
            nowPlayingInfoCenter.nowPlayingInfo?[MPMediaItemPropertyTitle] = name
            nowPlayingInfoCenter.nowPlayingInfo?[MPMediaItemPropertyAlbumTitle] = voiceActing.name

            if let season, let episode {
                nowPlayingInfoCenter.nowPlayingInfo?[MPMediaItemPropertyArtist] = "Season \(season.name) Episode \(episode.name)"
            }

            if let url = URL(string: poster) {
                session.request(url, method: .get, headers: [.userAgent(Const.userAgent)])
                    .validate(statusCode: 200 ..< 400)
                    .responseData { response in
                        guard let data = response.value,
                              !data.isEmpty,
                              response.error == nil,
                              let nsImage = NSImage(data: data)
                        else {
                            return
                        }

                        nowPlayingInfoCenter.nowPlayingInfo?[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: nsImage.size) { _ in nsImage }
                    }
                    .resume()
            }

            remoteCommandCenter.playCommand.addTarget { _ in
                player.playImmediately(atRate: rate)

                return .success
            }

            remoteCommandCenter.pauseCommand.addTarget { _ in
                player.pause()

                return .success
            }

            remoteCommandCenter.togglePlayPauseCommand.addTarget { _ in
                if isPlaying {
                    player.pause()
                } else {
                    player.playImmediately(atRate: rate)
                }

                return .success
            }

            remoteCommandCenter.changePlaybackPositionCommand.addTarget { event in
                guard let effectiveEvent = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }

                player.seek(to: CMTime(seconds: effectiveEvent.positionTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), toleranceBefore: .zero, toleranceAfter: .zero) { success in
                    if success {
                        updateNextTimer()
                    }
                }

                return .success
            }

            remoteCommandCenter.changePlaybackRateCommand.addTarget { event in
                guard let effectiveEvent = event as? MPChangePlaybackRateCommandEvent else { return .commandFailed }

                rate = effectiveEvent.playbackRate
                nowPlayingInfoCenter.nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = effectiveEvent.playbackRate

                if isPlaying {
                    player.playImmediately(atRate: effectiveEvent.playbackRate)
                }

                return .success
            }

            remoteCommandCenter.pauseCommand.isEnabled = true
            remoteCommandCenter.playCommand.isEnabled = true
            remoteCommandCenter.togglePlayPauseCommand.isEnabled = true
            remoteCommandCenter.changePlaybackPositionCommand.isEnabled = true
            remoteCommandCenter.changePlaybackRateCommand.isEnabled = true
            remoteCommandCenter.changePlaybackRateCommand.supportedPlaybackRates = rates.map { NSNumber(value: $0) }

            remoteCommandCenter.previousTrackCommand.isEnabled = false
            remoteCommandCenter.nextTrackCommand.isEnabled = false
            remoteCommandCenter.stopCommand.isEnabled = false
            remoteCommandCenter.changeRepeatModeCommand.isEnabled = false
            remoteCommandCenter.enableLanguageOptionCommand.isEnabled = false
            remoteCommandCenter.changeShuffleModeCommand.isEnabled = false
            remoteCommandCenter.skipForwardCommand.isEnabled = false
            remoteCommandCenter.skipBackwardCommand.isEnabled = false
            remoteCommandCenter.ratingCommand.isEnabled = false
            remoteCommandCenter.likeCommand.isEnabled = false
            remoteCommandCenter.dislikeCommand.isEnabled = false
            remoteCommandCenter.seekForwardCommand.isEnabled = false
            remoteCommandCenter.seekBackwardCommand.isEnabled = false
            remoteCommandCenter.bookmarkCommand.isEnabled = false
            remoteCommandCenter.disableLanguageOptionCommand.isEnabled = false

            player.volume = vol
            player.isMuted = muted

            withAnimation(.easeInOut) {
                playerLayer.player = player
                self.pipController = pipController
            }
        }
    }

    private func resetPlayer(completion: (() -> Void)? = nil) {
        if let timeObserverToken {
            playerLayer.player?.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }

        subscriptions.flush()

        nowPlayingInfoCenter.playbackState = .stopped
        nowPlayingInfoCenter.nowPlayingInfo = nil

        remoteCommandCenter.playCommand.removeTarget(nil)
        remoteCommandCenter.pauseCommand.removeTarget(nil)
        remoteCommandCenter.togglePlayPauseCommand.removeTarget(nil)
        remoteCommandCenter.changePlaybackPositionCommand.removeTarget(nil)
        remoteCommandCenter.changePlaybackRateCommand.removeTarget(nil)
        remoteCommandCenter.stopCommand.removeTarget(nil)
        remoteCommandCenter.previousTrackCommand.removeTarget(nil)
        remoteCommandCenter.nextTrackCommand.removeTarget(nil)

        timerWork?.cancel()
        delayHide?.cancel()

        thumbnails = nil

        playerLayer.player?.pause()
        playerLayer.player?.replaceCurrentItem(with: nil)

        withAnimation(.easeInOut) {
            playerLayer.player = nil
            pipController = nil
            error = nil
            nextTimer = nil
            subtitlesOptions = []
            isLoading = true
        }

        if let completion {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                completion()
            }
        }

        duration = .greatestFiniteMagnitude
        currentTime = 0.0
    }

    private func selectSubtitles(_ language: String?) {
        guard let player = playerLayer.player,
              let currentItem = player.currentItem
        else {
            return
        }

        currentItem.asset.loadMediaSelectionGroup(for: .legible) { mediaSelectionGroup, _ in
            if let mediaSelectionGroup {
                currentItem.select(mediaSelectionGroup.options.filter { $0.extendedLanguageTag != nil }.first(where: { $0.extendedLanguageTag == language }), in: mediaSelectionGroup)

                if let position = selectPositions.first(where: { position in
                    position.id == voiceActing.voiceId
                }) {
                    position.subtitles = language

                    position.managedObjectContext?.saveContext()
                } else {
                    let position = SelectPosition(context: viewContext)
                    position.id = voiceActing.voiceId
                    position.acting = voiceActing.translatorId
                    position.season = season?.seasonId
                    position.episode = episode?.episodeId
                    position.subtitles = language

                    viewContext.saveContext()
                }
            }
        }
    }

    private func resetTimer() {
        timerWork?.cancel()

        updateNextTimer()

        guard let timer,
              timer > 0,
              isPlaying
        else {
            return
        }

        timerWork = DispatchWorkItem {
            guard let player = playerLayer.player,
                  player.status == .readyToPlay
            else {
                return
            }

            player.pause()
        }

        if let timerWork {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(timer), execute: timerWork)
        }
    }

    private func setMask(_ newValue: Bool) {
        withAnimation(.easeInOut) {
            isMaskShow = newValue
        }

        delayHide?.cancel()

        if newValue, !isLoading, isPlaying {
            delayHide = DispatchWorkItem {
                showCursor(false)

                setMask(false)
            }

            if let delayHide {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3, execute: delayHide)
            }
        }
    }

    private func updateNextTimer() {
        if (duration - currentTime) / 60 > 0, (duration - currentTime) / 60 <= 1, let seasons, let season, let episode, seasons.element(after: season) != nil || season.episodes.element(after: episode) != nil, timer != -1, !isPictureInPictureActive {
            withAnimation(.easeInOut) {
                nextTimer = min((duration - currentTime) / 60, 1.0)
            }
        } else if nextTimer != nil {
            withAnimation(.easeInOut) {
                nextTimer = nil
            }
        }
    }

    private func showCursor(_ isShowed: Bool = true) {
        if isShowed {
            NSCursor.unhide()
        } else {
            NSCursor.setHiddenUntilMouseMoves(true)
        }
    }

    private func prevTrack(_ seasons: [MovieSeason], _ season: MovieSeason, _ episode: MovieEpisode) {
        if let prevEpisode = season.episodes.element(before: episode) {
            withAnimation(.easeInOut(duration: 0.15)) {
                isLoading = true
            }

            resetPlayer {
                getMovieVideoUseCase(voiceActing: voiceActing, season: season, episode: prevEpisode, favs: favs)
                    .receive(on: DispatchQueue.main)
                    .sink { completion in
                        guard case let .failure(error) = completion else { return }

                        resetPlayer {
                            withAnimation(.easeInOut) {
                                self.error = error
                            }
                        }
                    } receiveValue: { movie in
                        if movie.needPremium {
                            dismiss()

                            appState.isPremiumPresented = true
                        } else {
                            if isLoggedIn {
                                saveWatchingStateUseCase(voiceActing: voiceActing, season: season, episode: prevEpisode, position: 0, total: 0)
                                    .sink { _ in } receiveValue: { _ in }
                                    .store(in: &subscriptions)
                            }

                            if let position = selectPositions.first(where: { position in
                                position.id == voiceActing.voiceId
                            }) {
                                position.acting = voiceActing.translatorId
                                position.season = season.seasonId
                                position.episode = prevEpisode.episodeId

                                position.managedObjectContext?.saveContext()
                            } else {
                                let position = SelectPosition(context: viewContext)

                                position.id = voiceActing.voiceId
                                position.acting = voiceActing.translatorId
                                position.season = season.seasonId
                                position.episode = prevEpisode.episodeId

                                viewContext.saveContext()
                            }

                            self.movie = movie
                            self.episode = prevEpisode

                            setupPlayer(isMuted: isMuted, subtitles: subtitles, volume: volume)
                        }
                    }
                    .store(in: &subscriptions)
            }
        } else if let prevSeason = seasons.element(before: season), let prevEpisode = prevSeason.episodes.last {
            withAnimation(.easeInOut(duration: 0.15)) {
                isLoading = true
            }

            resetPlayer {
                getMovieVideoUseCase(voiceActing: voiceActing, season: prevSeason, episode: prevEpisode, favs: favs)
                    .receive(on: DispatchQueue.main)
                    .sink { completion in
                        guard case let .failure(error) = completion else { return }

                        resetPlayer {
                            withAnimation(.easeInOut) {
                                self.error = error
                            }
                        }
                    } receiveValue: { movie in
                        if movie.needPremium {
                            dismiss()

                            appState.isPremiumPresented = true
                        } else {
                            if isLoggedIn {
                                saveWatchingStateUseCase(voiceActing: voiceActing, season: prevSeason, episode: prevEpisode, position: 0, total: 0)
                                    .sink { _ in } receiveValue: { _ in }
                                    .store(in: &subscriptions)
                            }

                            if let position = selectPositions.first(where: { position in
                                position.id == voiceActing.voiceId
                            }) {
                                position.acting = voiceActing.translatorId
                                position.season = prevSeason.seasonId
                                position.episode = prevEpisode.episodeId

                                position.managedObjectContext?.saveContext()
                            } else {
                                let position = SelectPosition(context: viewContext)

                                position.id = voiceActing.voiceId
                                position.acting = voiceActing.translatorId
                                position.season = prevSeason.seasonId
                                position.episode = prevEpisode.episodeId

                                viewContext.saveContext()
                            }

                            self.movie = movie
                            self.season = prevSeason
                            self.episode = prevEpisode

                            setupPlayer(isMuted: isMuted, subtitles: subtitles, volume: volume)
                        }
                    }
                    .store(in: &subscriptions)
            }
        }
    }

    private func nextTrack(_ seasons: [MovieSeason], _ season: MovieSeason, _ episode: MovieEpisode) {
        if let nextEpisode = season.episodes.element(after: episode) {
            withAnimation(.easeInOut(duration: 0.15)) {
                isLoading = true
            }

            resetPlayer {
                getMovieVideoUseCase(voiceActing: voiceActing, season: season, episode: nextEpisode, favs: favs)
                    .receive(on: DispatchQueue.main)
                    .sink { completion in
                        guard case let .failure(error) = completion else { return }

                        resetPlayer {
                            withAnimation(.easeInOut) {
                                self.error = error
                            }
                        }
                    } receiveValue: { movie in
                        if movie.needPremium {
                            dismiss()

                            appState.isPremiumPresented = true
                        } else {
                            if isLoggedIn {
                                saveWatchingStateUseCase(voiceActing: voiceActing, season: season, episode: nextEpisode, position: 0, total: 0)
                                    .sink { _ in } receiveValue: { _ in }
                                    .store(in: &subscriptions)
                            }

                            if let position = selectPositions.first(where: { position in
                                position.id == voiceActing.voiceId
                            }) {
                                position.acting = voiceActing.translatorId
                                position.season = season.seasonId
                                position.episode = nextEpisode.episodeId

                                position.managedObjectContext?.saveContext()
                            } else {
                                let position = SelectPosition(context: viewContext)

                                position.id = voiceActing.voiceId
                                position.acting = voiceActing.translatorId
                                position.season = season.seasonId
                                position.episode = nextEpisode.episodeId

                                viewContext.saveContext()
                            }

                            self.movie = movie
                            self.episode = nextEpisode

                            setupPlayer(isMuted: isMuted, subtitles: subtitles, volume: volume)
                        }
                    }
                    .store(in: &subscriptions)
            }
        } else if let nextSeason = seasons.element(after: season), let nextEpisode = nextSeason.episodes.first {
            withAnimation(.easeInOut(duration: 0.15)) {
                isLoading = true
            }

            resetPlayer {
                getMovieVideoUseCase(voiceActing: voiceActing, season: nextSeason, episode: nextEpisode, favs: favs)
                    .receive(on: DispatchQueue.main)
                    .sink { completion in
                        guard case let .failure(error) = completion else { return }

                        resetPlayer {
                            withAnimation(.easeInOut) {
                                self.error = error
                            }
                        }
                    } receiveValue: { movie in
                        if movie.needPremium {
                            dismiss()

                            appState.isPremiumPresented = true
                        } else {
                            if isLoggedIn {
                                saveWatchingStateUseCase(voiceActing: voiceActing, season: nextSeason, episode: nextEpisode, position: 0, total: 0)
                                    .sink { _ in } receiveValue: { _ in }
                                    .store(in: &subscriptions)
                            }

                            if let position = selectPositions.first(where: { position in
                                position.id == voiceActing.voiceId
                            }) {
                                position.acting = voiceActing.translatorId
                                position.season = nextSeason.seasonId
                                position.episode = nextEpisode.episodeId

                                position.managedObjectContext?.saveContext()
                            } else {
                                let position = SelectPosition(context: viewContext)

                                position.id = voiceActing.voiceId
                                position.acting = voiceActing.translatorId
                                position.season = nextSeason.seasonId
                                position.episode = nextEpisode.episodeId

                                viewContext.saveContext()
                            }

                            self.movie = movie
                            self.season = nextSeason
                            self.episode = nextEpisode

                            setupPlayer(isMuted: isMuted, subtitles: subtitles, volume: volume)
                        }
                    }
                    .store(in: &subscriptions)
            }
        }
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
