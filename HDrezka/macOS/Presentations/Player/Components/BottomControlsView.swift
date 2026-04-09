import AVKit
import Defaults
import SwiftUI

struct BottomControlsView: View {
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
        .opacity(viewModel.isMaskShow ? 1 : 0)
    }
}
