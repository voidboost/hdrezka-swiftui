import AVKit
import ComposableArchitecture
import Defaults
import SwiftUI

struct BottomControlsView: View {
    @Environment(StoreOf<PlayerFeature>.self) private var store

    @Default(.videoGravity) private var videoGravity
    @Default(.ambientLight) private var ambientLight
    @Default(.rate) private var rate

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading) {
                    HStack(alignment: .center) {
                        if let season = store.season, let episode = store.episode {
                            Text("key.season-\(season.name).episode-\(episode.name)")
                                .font(.title2.bold())
                                .lineLimit(1)
                                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                        }

                        Text(store.voiceActing.name)
                            .font(.title2.bold())
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                    }

                    Text(store.name)
                        .font(.largeTitle.bold())
                        .lineLimit(1)
                        .help(store.name)
                        .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                }

                Spacer()

                HStack(alignment: .center, spacing: 12) {
                    if !store.subtitlesOptions.isEmpty {
                        Menu {
                            Picker("key.subtitles", selection: Binding {
                                store.subtitles
                            } set: { subtitles in
                                store.send(.subtitlesSelected(subtitles))
                            }) {
                                Text("key.off").tag(nil as String?)

                                ForEach(store.subtitlesOptions) { subtitles in
                                    Text(subtitles.displayName).tag(subtitles.tag as String?)
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
                                if isPressed {
                                    store.send(.lockMask(true), animation: .easeInOut)
                                } else {
                                    store.send(.unlockMask(true), animation: .easeInOut)
                                }
                            },
                        )
                        .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                    }

                    Menu {
                        Picker("key.timer", systemImage: "timer", selection: Binding {
                            store.timer
                        } set: {
                            store.send(.timerSelected($0))
                        }) {
                            Text("key.off").tag(nil as Int?)

                            ForEach(store.times, id: \.self) { time in
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

                        Picker("key.video_gravity", systemImage: "arrow.up.left.and.arrow.down.right.rectangle", selection: $videoGravity) {
                            ForEach(VideoGravity.allCases) { videoGravity in
                                Text(videoGravity.localizedKey).tag(videoGravity)
                            }
                        }
                        .pickerStyle(.menu)

                        Picker("key.ambient_light", systemImage: "light.panel", selection: $ambientLight) {
                            Text("key.on").tag(true)

                            Text("key.off").tag(false)
                        }
                        .pickerStyle(.menu)

                        Picker("key.speed", systemImage: "gauge.with.needle", selection: $rate) {
                            ForEach(PlayerEngine.rates, id: \.self) { value in
                                Text(verbatim: "\(value)x").tag(value)
                            }
                        }
                        .pickerStyle(.menu)

                        if !store.movie.getAvailableQualities().isEmpty {
                            Picker("key.quality", systemImage: "4k.tv", selection: Binding {
                                store.quality
                            } set: {
                                store.send(.qualitySelected($0))
                            }) {
                                ForEach(store.movie.getAvailableQualities(), id: \.self) { value in
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
                            if isPressed {
                                store.send(.lockMask(true), animation: .easeInOut)
                            } else {
                                store.send(.unlockMask(true), animation: .easeInOut)
                            }
                        },
                    )
                    .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                }
            }

            SeekBarView()
        }
        .padding(.horizontal, 36)
        .padding(.bottom, 36)
        .opacity(store.isMaskShow ? 1 : 0)
        .animation(.easeInOut, value: store.isMaskShow)
    }
}
