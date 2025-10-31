import AVKit
import Combine
import Defaults
import FactoryKit
import Kingfisher
import MediaPlayer
import SwiftData
import SwiftUI

struct PlayerView: View {
    @Injected(\.saveWatchingStateUseCase) private var saveWatchingStateUseCase
    @Injected(\.getMovieThumbnailsUseCase) private var getMovieThumbnailsUseCase
    @Injected(\.getMovieVideoUseCase) private var getMovieVideoUseCase

    @Default(.isLoggedIn) private var isLoggedIn
    @Default(.spatialAudio) private var spatialAudio
    @Default(.rate) private var rate
    @Default(.volume) private var volume
    @Default(.isMuted) private var isMuted
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Environment(AppState.self) private var appState

    @Query private var playerPositions: [PlayerPosition]
    @Query private var selectPositions: [SelectPosition]

    @State private var playerSubscriptions: Set<AnyCancellable> = []
    @State private var layerSubscriptions: Set<AnyCancellable> = []

    private let poster: String
    private let name: String
    private let favs: String
    private let voiceActing: MovieVoiceActing

    private let times: [Int]

    @State private var seasons: [MovieSeason]?
    @State private var season: MovieSeason?
    @State private var episode: MovieEpisode?
    @State private var movie: MovieVideo
    @State private var quality: String

    private let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    private let remoteCommandCenter = MPRemoteCommandCenter.shared()

    @State private var player: AVPlayer?
    @State private var playerLayer: AVPlayerLayer?
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
    @State private var currentTime: Double = .zero
    @State private var duration: Double = .greatestFiniteMagnitude
    @State private var error: Error?
    @State private var subtitles: String?
    @State private var isPlaying: Bool = true
    @State private var isLoading: Bool = true
    @State private var isMaskShow: Bool = true
    @State private var delayHide: DispatchWorkItem?
    @State private var subtitlesOptions: [AVMediaSelectionOption] = []
    @State private var thumbnails: WebVTT?
    @State private var initialVolume: Float = .zero
    @State private var topInset: CGFloat = .zero

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

        try? AVAudioSession.sharedInstance().setCategory(.playback)
    }

    var body: some View {
        Group {
            if let error {
                ErrorStateView(error) {
                    resetPlayer {
                        setupPlayer(subtitles: subtitles)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(36)
            } else if let player {
                GeometryReader { geometry in
                    CustomVideoPlayer(player: player, playerLayer: $playerLayer)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .contentShape(.rect)
                        .task(id: playerLayer) {
                            if let playerLayer {
                                layerSubscriptions.flush()

                                playerLayer.videoGravity = videoGravity

                                playerLayer.publisher(for: \.videoGravity)
                                    .receive(on: DispatchQueue.main)
                                    .sink { videoGravity in
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            self.videoGravity = videoGravity
                                        }
                                    }
                                    .store(in: &layerSubscriptions)

                                let pipController = AVPictureInPictureController(playerLayer: playerLayer)

                                if let pipController {
                                    pipController.publisher(for: \.isPictureInPictureActive)
                                        .receive(on: DispatchQueue.main)
                                        .sink { isPictureInPictureActive in
                                            withAnimation(.easeInOut) {
                                                self.isPictureInPictureActive = isPictureInPictureActive
                                            }

                                            setMask(!isPictureInPictureActive)

                                            updateNextTimer()
                                        }
                                        .store(in: &layerSubscriptions)

                                    pipController.publisher(for: \.isPictureInPicturePossible)
                                        .receive(on: DispatchQueue.main)
                                        .sink { isPictureInPicturePossible in
                                            withAnimation(.easeInOut(duration: 0.15)) {
                                                self.isPictureInPicturePossible = isPictureInPicturePossible
                                            }
                                        }
                                        .store(in: &layerSubscriptions)
                                }

                                withAnimation(.easeInOut) {
                                    self.pipController = pipController
                                }
                            }
                        }
                        .gesture(
                            SpatialTapGesture(count: 2)
                                .onEnded { event in
                                    guard player.status == .readyToPlay,
                                          !isPictureInPictureActive
                                    else {
                                        return
                                    }

                                    if event.location.x / geometry.size.width > 0.5 {
                                        player.seek(to: CMTime(seconds: min(currentTime + 10.0, duration), preferredTimescale: CMTimeScale(NSEC_PER_SEC)), toleranceBefore: .zero, toleranceAfter: .zero) { complete in
                                            if isPlaying, complete {
                                                player.playImmediately(atRate: rate)
                                            }
                                        }

                                        currentTime = min(currentTime + 10.0, duration)
                                    } else {
                                        player.seek(to: CMTime(seconds: max(currentTime - 10.0, 0.0), preferredTimescale: CMTimeScale(NSEC_PER_SEC)), toleranceBefore: .zero, toleranceAfter: .zero) { complete in
                                            if isPlaying, complete {
                                                player.playImmediately(atRate: rate)
                                            }
                                        }

                                        currentTime = max(currentTime - 10.0, 0.0)
                                    }
                                }
                                .exclusively(before:
                                    TapGesture(count: 1)
                                        .onEnded {
                                            if !isMaskShow {
                                                setMask(!isPictureInPictureActive)
                                            } else {
                                                setMask((isLoading || !isPlaying) && !isPictureInPictureActive)
                                            }
                                        }
                                        .exclusively(before:
                                            DragGesture(minimumDistance: 0)
                                                .onChanged { drag in
                                                    if drag.startLocation.x > geometry.size.width / 2 {
                                                        let delta = -drag.translation.height / (geometry.size.height / 2)

                                                        player.volume = min(max(initialVolume + Float(delta), 0), 1)
                                                    }
                                                }
                                                .onEnded { drag in
                                                    if drag.startLocation.x > geometry.size.width / 2 {
                                                        initialVolume = player.volume
                                                    }
                                                })),
                        )
                        .overlay(alignment: .topTrailing) {
                            if isMaskShow {
                                HStack(alignment: .center) {
                                    SliderWithoutText(value: Binding {
                                        volume
                                    } set: { volume in
                                        player.volume = volume
                                    }, inRange: 0 ... 1, activeFillColor: .primary, fillColor: .primary.opacity(0.7), emptyColor: .primary.opacity(0.3), height: 8)
                                        .frame(width: 120, height: 10)
                                        .shadow(color: .black.opacity(0.5), radius: 4, y: 2)

                                    VStack(alignment: .center) {
                                        Button {
                                            resetTimer()

                                            if !isPictureInPictureActive {
                                                player.isMuted.toggle()
                                            }
                                        } label: {
                                            Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.3.fill", variableValue: Double(volume))
                                                .font(.title2)
                                                .contentTransition(.symbolEffect(.replace))
                                                .contentShape(.circle)
                                        }
                                        .buttonStyle(.plain)
                                        .keyboardShortcut("m", modifiers: [])
                                        .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                                    }
                                    .frame(width: 30, height: 30)
                                }
                                .padding(.top, 36)
                                .padding(.trailing, 36)
                            }
                        }
                        .overlay(alignment: .center) {
                            if isMaskShow {
                                HStack(alignment: .center) {
                                    if let seasons, let season, let episode {
                                        Button {
                                            prevTrack(seasons, season, episode)
                                        } label: {
                                            Image(systemName: "backward.fill")
                                                .font(.title2)
                                                .contentShape(.circle)
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
                                                .font(.largeTitle)
                                                .contentTransition(.symbolEffect(.replace))
                                                .contentShape(.circle)
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
                                                .font(.title2)
                                                .contentShape(.circle)
                                        }
                                        .buttonStyle(.plain)
                                        .disabled(seasons.element(after: season) == nil && season.episodes.element(after: episode) == nil)
                                        .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                                    }
                                }
                                .frame(width: 160)
                            }
                        }
                        .overlay(alignment: .bottom) {
                            if isMaskShow {
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

                                        HStack(alignment: .center, spacing: 12) {
                                            if let pipController, AVPictureInPictureController.isPictureInPictureSupported() {
                                                Button {
                                                    pipController.startPictureInPicture()
                                                } label: {
                                                    Image(systemName: "pip.enter")
                                                        .font(.title2)
                                                        .contentShape(.circle)
                                                }
                                                .buttonStyle(.plain)
                                                .disabled(isPictureInPictureActive || !isPictureInPicturePossible)
                                                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                                            }

                                            if !subtitlesOptions.isEmpty {
                                                Menu {
                                                    Picker("key.subtitles", selection: Binding {
                                                        subtitles
                                                    } set: { subtitles in
                                                        self.subtitles = subtitles

                                                        selectSubtitles(subtitles)
                                                    }) {
                                                        Text("key.off").tag(nil as String?)

                                                        ForEach(subtitlesOptions, id: \.self) { subtitles in
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
                                                        setMask(true, force: isPressed)
                                                    },
                                                )
                                                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                                            }

                                            Menu {
                                                Picker("key.timer", selection: Binding {
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
                                                }
                                                .pickerStyle(.menu)

                                                if let playerLayer {
                                                    Picker("key.video_gravity", selection: Binding {
                                                        videoGravity
                                                    } set: {
                                                        playerLayer.videoGravity = $0
                                                    }) {
                                                        Text("key.video_gravity.fit").tag(AVLayerVideoGravity.resizeAspect)

                                                        Text("key.video_gravity.fill").tag(AVLayerVideoGravity.resizeAspectFill)

                                                        Text("key.video_gravity.stretch").tag(AVLayerVideoGravity.resize)
                                                    }
                                                    .pickerStyle(.menu)
                                                }

                                                Picker("key.speed", selection: Binding {
                                                    rate
                                                } set: { rate in
                                                    self.rate = rate
                                                    nowPlayingInfoCenter.nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = rate

                                                    if isPlaying {
                                                        player.playImmediately(atRate: rate)
                                                    }
                                                }) {
                                                    ForEach(rates, id: \.self) { value in
                                                        Text(verbatim: "\(value)x").tag(value)
                                                    }
                                                }
                                                .pickerStyle(.menu)

                                                if !movie.getAvailableQualities().isEmpty {
                                                    Picker("key.quality", selection: Binding {
                                                        quality
                                                    } set: {
                                                        quality = $0

                                                        let currentSeek = player.currentTime()

                                                        resetPlayer {
                                                            setupPlayer(seek: currentSeek, isPlaying: isPlaying, subtitles: subtitles)
                                                        }
                                                    }) {
                                                        ForEach(movie.getAvailableQualities(), id: \.self) { value in
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
                                                    setMask(true, force: isPressed)
                                                },
                                            )
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
                                    }, inRange: 0 ... duration, buffers: loadedTimeRanges, activeFillColor: .primary, fillColor: .primary.opacity(0.7), emptyColor: .primary.opacity(0.3), height: 8, thumbnails: thumbnails) { _ in }
                                        .frame(height: 25)
                                        .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                                }
                                .padding(.horizontal, 36)
                                .padding(.bottom, 36)
                            }
                        }
                        .overlay(alignment: .topTrailing) {
                            if let nextTimer, let seasons, let season, let episode {
                                Button {
                                    nextTrack(seasons, season, episode)
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
                                    .background(.ultraThinMaterial, in: .rect(topLeadingRadius: 6, bottomLeadingRadius: 6))
                                }
                                .buttonStyle(.plain)
                                .padding(.top, 102)
                                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                            }
                        }
                }
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .safeAreaPadding(.top)
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .topLeading) {
            if isMaskShow || isPictureInPictureActive || isLoading {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .contentShape(.circle)
                }
                .buttonStyle(.plain)
                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                .padding(.top, 36)
                .padding(.leading, 36)
            }
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
        .statusBarHidden(!isMaskShow && !isPictureInPictureActive)
        .persistentSystemOverlays(.hidden)
        .onAppear {
            initialVolume = volume

            setupPlayer(subtitles: selectPositions.first(where: { position in position.id == voiceActing.voiceId })?.subtitles)
        }
        .onDisappear {
            resetPlayer()
        }
        .onChange(of: scenePhase) {
            guard let player,
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
        .onChange(of: spatialAudio) {
            guard let player,
                  player.status == .readyToPlay,
                  let currentItem = player.currentItem
            else {
                return
            }

            currentItem.allowedAudioSpatializationFormats = spatialAudio.format
        }
    }

    private func setupPlayer(seek: CMTime? = nil, isPlaying playing: Bool = true, subtitles: String? = nil) {
        guard let url = movie.getClosestTo(quality: quality)?.hls else { return }

        let player = CustomAVPlayer(m3u8: url, subtitles: movie.subtitles)

        if let player, let currentItem = player.currentItem {
            nowPlayingInfoCenter.nowPlayingInfo = [:]

            if let thumbnails = movie.thumbnails {
                getMovieThumbnailsUseCase(path: thumbnails)
                    .receive(on: DispatchQueue.main)
                    .sink { _ in } receiveValue: { thumbnails in
                        self.thumbnails = thumbnails
                    }
                    .store(in: &playerSubscriptions)
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
                } else {
                    let position = PlayerPosition(
                        id: voiceActing.voiceId,
                        acting: voiceActing.translatorId,
                        season: season?.seasonId,
                        episode: episode?.episodeId,
                        position: currentTime,
                    )

                    modelContext.insert(position)
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
                                } completion: {
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
                .store(in: &playerSubscriptions)

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

                    setMask(!isPictureInPictureActive)

                    updateNextTimer()
                }
                .store(in: &playerSubscriptions)

            player.publisher(for: \.isMuted)
                .receive(on: DispatchQueue.main)
                .sink { isMuted in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        self.isMuted = isMuted
                    }

                    setMask(!isPictureInPictureActive)

                    updateNextTimer()
                }
                .store(in: &playerSubscriptions)

            player.publisher(for: \.volume)
                .receive(on: DispatchQueue.main)
                .sink { volume in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        self.volume = volume
                    }

                    if isMuted {
                        player.isMuted.toggle()
                    }

                    setMask(!isPictureInPictureActive)

                    updateNextTimer()
                }
                .store(in: &playerSubscriptions)

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
                .store(in: &playerSubscriptions)

            currentItem.publisher(for: \.duration)
                .compactMap(\.self)
                .filter { $0.isValid && !$0.isIndefinite && !$0.isNegativeInfinity && !$0.isPositiveInfinity && $0.seconds > 0 }
                .receive(on: DispatchQueue.main)
                .sink { duration in
                    self.duration = duration.seconds

                    nowPlayingInfoCenter.nowPlayingInfo?[MPMediaItemPropertyPlaybackDuration] = duration.seconds

                    updateNextTimer()
                }
                .store(in: &playerSubscriptions)

            currentItem.publisher(for: \.loadedTimeRanges)
                .compactMap { $0 as? [CMTimeRange] }
                .receive(on: DispatchQueue.main)
                .sink { loadedTimeRanges in
                    self.loadedTimeRanges = loadedTimeRanges
                }
                .store(in: &playerSubscriptions)

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
                .store(in: &playerSubscriptions)

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
                .store(in: &playerSubscriptions)

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
                .store(in: &playerSubscriptions)

            nowPlayingInfoCenter.nowPlayingInfo?[MPNowPlayingInfoPropertyAssetURL] = url
            nowPlayingInfoCenter.nowPlayingInfo?[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.video.rawValue
            nowPlayingInfoCenter.nowPlayingInfo?[MPNowPlayingInfoPropertyIsLiveStream] = false
            nowPlayingInfoCenter.nowPlayingInfo?[MPMediaItemPropertyTitle] = name
            nowPlayingInfoCenter.nowPlayingInfo?[MPMediaItemPropertyAlbumTitle] = voiceActing.name

            if let season, let episode {
                nowPlayingInfoCenter.nowPlayingInfo?[MPMediaItemPropertyArtist] = "Season \(season.name) Episode \(episode.name)"
            }

            if let url = URL(string: poster) {
                KingfisherManager.shared.retrieveImage(with: url) { result in
                    if case let .success(value) = result {
                        nowPlayingInfoCenter.nowPlayingInfo?[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: value.image.size) { _ in value.image }
                    }
                }
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

            player.volume = volume
            player.isMuted = isMuted

            withAnimation(.easeInOut) {
                self.player = player
            }
        }
    }

    private func resetPlayer(completion: (() -> Void)? = nil) {
        if let timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }

        layerSubscriptions.flush()
        playerSubscriptions.flush()

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

        player?.pause()
        player?.replaceCurrentItem(with: nil)

        withAnimation(.easeInOut) {
            player = nil
            pipController = nil
            error = nil
            nextTimer = nil
            subtitlesOptions = []
            isLoading = true
        } completion: {
            completion?()
        }

        duration = .greatestFiniteMagnitude
        currentTime = 0.0
    }

    private func selectSubtitles(_ language: String?) {
        guard let player,
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
                } else {
                    let position = SelectPosition(
                        id: voiceActing.voiceId,
                        acting: voiceActing.translatorId,
                        season: season?.seasonId,
                        episode: episode?.episodeId,
                        subtitles: language,
                    )

                    modelContext.insert(position)
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
            guard let player,
                  player.status == .readyToPlay
            else {
                return
            }

            player.pause()
        }

        if let timerWork {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(timer), execute: timerWork)
        }
    }

    private func setMask(_ newValue: Bool, force: Bool = false) {
        withAnimation(.easeInOut) {
            isMaskShow = newValue
        }

        delayHide?.cancel()

        if newValue, !isLoading, isPlaying, !force {
            delayHide = DispatchWorkItem {
                setMask(false)
            }

            if let delayHide {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: delayHide)
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

                        withAnimation(.easeInOut) {
                            self.error = error
                        }
                    } receiveValue: { movie in
                        if movie.needPremium {
                            dismiss()

                            appState.isPremiumPresented = true
                        } else {
                            if isLoggedIn {
                                saveWatchingStateUseCase(voiceActing: voiceActing, season: season, episode: prevEpisode, position: 0, total: 0)
                                    .sink { _ in } receiveValue: { _ in }
                                    .store(in: &playerSubscriptions)
                            }

                            if let position = selectPositions.first(where: { position in
                                position.id == voiceActing.voiceId
                            }) {
                                position.acting = voiceActing.translatorId
                                position.season = season.seasonId
                                position.episode = prevEpisode.episodeId

                            } else {
                                let position = SelectPosition(
                                    id: voiceActing.voiceId,
                                    acting: voiceActing.translatorId,
                                    season: season.seasonId,
                                    episode: prevEpisode.episodeId,
                                )

                                modelContext.insert(position)
                            }

                            self.movie = movie
                            self.episode = prevEpisode

                            setupPlayer(subtitles: subtitles)
                        }
                    }
                    .store(in: &playerSubscriptions)
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

                        withAnimation(.easeInOut) {
                            self.error = error
                        }
                    } receiveValue: { movie in
                        if movie.needPremium {
                            dismiss()

                            appState.isPremiumPresented = true
                        } else {
                            if isLoggedIn {
                                saveWatchingStateUseCase(voiceActing: voiceActing, season: prevSeason, episode: prevEpisode, position: 0, total: 0)
                                    .sink { _ in } receiveValue: { _ in }
                                    .store(in: &playerSubscriptions)
                            }

                            if let position = selectPositions.first(where: { position in
                                position.id == voiceActing.voiceId
                            }) {
                                position.acting = voiceActing.translatorId
                                position.season = prevSeason.seasonId
                                position.episode = prevEpisode.episodeId
                            } else {
                                let position = SelectPosition(
                                    id: voiceActing.voiceId,
                                    acting: voiceActing.translatorId,
                                    season: prevSeason.seasonId,
                                    episode: prevEpisode.episodeId,
                                )

                                modelContext.insert(position)
                            }

                            self.movie = movie
                            self.season = prevSeason
                            self.episode = prevEpisode

                            setupPlayer(subtitles: subtitles)
                        }
                    }
                    .store(in: &playerSubscriptions)
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

                        withAnimation(.easeInOut) {
                            self.error = error
                        }
                    } receiveValue: { movie in
                        if movie.needPremium {
                            dismiss()

                            appState.isPremiumPresented = true
                        } else {
                            if isLoggedIn {
                                saveWatchingStateUseCase(voiceActing: voiceActing, season: season, episode: nextEpisode, position: 0, total: 0)
                                    .sink { _ in } receiveValue: { _ in }
                                    .store(in: &playerSubscriptions)
                            }

                            if let position = selectPositions.first(where: { position in
                                position.id == voiceActing.voiceId
                            }) {
                                position.acting = voiceActing.translatorId
                                position.season = season.seasonId
                                position.episode = nextEpisode.episodeId
                            } else {
                                let position = SelectPosition(
                                    id: voiceActing.voiceId,
                                    acting: voiceActing.translatorId,
                                    season: season.seasonId,
                                    episode: nextEpisode.episodeId,
                                )

                                modelContext.insert(position)
                            }

                            self.movie = movie
                            self.episode = nextEpisode

                            setupPlayer(subtitles: subtitles)
                        }
                    }
                    .store(in: &playerSubscriptions)
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

                        withAnimation(.easeInOut) {
                            self.error = error
                        }
                    } receiveValue: { movie in
                        if movie.needPremium {
                            dismiss()

                            appState.isPremiumPresented = true
                        } else {
                            if isLoggedIn {
                                saveWatchingStateUseCase(voiceActing: voiceActing, season: nextSeason, episode: nextEpisode, position: 0, total: 0)
                                    .sink { _ in } receiveValue: { _ in }
                                    .store(in: &playerSubscriptions)
                            }

                            if let position = selectPositions.first(where: { position in
                                position.id == voiceActing.voiceId
                            }) {
                                position.acting = voiceActing.translatorId
                                position.season = nextSeason.seasonId
                                position.episode = nextEpisode.episodeId
                            } else {
                                let position = SelectPosition(
                                    id: voiceActing.voiceId,
                                    acting: voiceActing.translatorId,
                                    season: nextSeason.seasonId,
                                    episode: nextEpisode.episodeId,
                                )

                                modelContext.insert(position)
                            }

                            self.movie = movie
                            self.season = nextSeason
                            self.episode = nextEpisode

                            setupPlayer(subtitles: subtitles)
                        }
                    }
                    .store(in: &playerSubscriptions)
            }
        }
    }
}

class CustomPlayerView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }

    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }

    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}

struct CustomVideoPlayer: UIViewRepresentable {
    private let player: AVPlayer
    @Binding private var playerLayer: AVPlayerLayer?

    init(player: AVPlayer, playerLayer: Binding<AVPlayerLayer?>) {
        self.player = player
        _playerLayer = playerLayer
    }

    func makeUIView(context _: Context) -> CustomPlayerView {
        let view = CustomPlayerView()
        view.player = player
        return view
    }

    func updateUIView(_ uiView: CustomPlayerView, context _: Context) {
        uiView.player = player

        if playerLayer !== uiView.playerLayer {
            DispatchQueue.main.async {
                playerLayer = uiView.playerLayer
            }
        }
    }
}
