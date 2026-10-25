import AVKit
import ComposableArchitecture
import Defaults
import SQLiteData
import SwiftUI

extension PlayerFeature {
    func handle(_ event: PlayerEvent, _ state: inout State) -> Effect<Action> {
        switch event {
        case let .time(seconds):
            state.currentTime = seconds
            updateNextTimer(&state)

            return .none

        case let .positionTick(seconds):
            return .run { [voiceActing = state.voiceActing, season = state.season, episode = state.episode] _ in
                try? await database.write { db in
                    try PlayerPosition
                        .upsert {
                            PlayerPosition.Draft(
                                id: PlayerPosition.ID(
                                    id: voiceActing.voiceId,
                                    acting: voiceActing.translatorId,
                                    season: season?.seasonId,
                                    episode: episode?.episodeId
                                ),
                                position: seconds
                            )
                        }
                        .execute(db)
                }
            }

        case .status(.readyToPlay):
            state.isReady = true
            state.isFocused = true
            updateNextTimer(&state)

            return .merge(
                .run { [voiceActing = state.voiceActing, season = state.season, episode = state.episode, subtitles = state.subtitles] _ in
                    if Defaults[.isLoggedIn] {
                        try? await saveWatchingStateUseCase(voiceActing: voiceActing, season: season, episode: episode)
                    }

                    try? await database.write { db in
                        try SelectPosition
                            .upsert {
                                SelectPosition.Draft(
                                    id: voiceActing.voiceId,
                                    acting: voiceActing.translatorId,
                                    season: season?.seasonId,
                                    episode: episode?.episodeId,
                                    subtitles: subtitles
                                )
                            }
                            .execute(db)
                    }
                },
                .run { [engine, subtitles = state.subtitles] send in
                    let options = await engine.subtitleOptions(selecting: subtitles)

                    await send(.subtitleOptionsLoaded(options), animation: .easeInOut(duration: 0.15))
                },
                perform { [mode = state.trackCommandMode] engine in engine.configureTrackCommands(mode) },
                startPlayback(state)
            )

        case .status:
            return .none

        case let .timeControlStatus(status):
            switch status {
            case .playing:
                state.isPlaying = true
                state.isLoading = false
            case .paused:
                state.isPlaying = false
                state.isLoading = false
            default:
                state.isPlaying = false
                state.isLoading = true
            }

            updateNextTimer(&state)

            return .merge(showCursor(), setMask(!state.isPictureInPictureActive, &state))

        case let .isMuted(isMuted):
            updateNextTimer(&state)

            return .merge(
                .run { _ in Defaults[.isMuted] = isMuted },
                showCursor(),
                setMask(!state.isPictureInPictureActive, &state)
            )

        case let .volume(volume):
            updateNextTimer(&state)

            return .merge(
                perform { engine in
                    Defaults[.volume] = volume

                    engine.setMuted(Defaults[.isMuted])
                },
                showCursor(),
                setMask(!state.isPictureInPictureActive, &state)
            )

        case let .duration(duration):
            state.duration = duration
            updateNextTimer(&state)

            return .none

        case let .loadedTimeRanges(ranges):
            state.loadedTimeRanges = ranges

            return .none

        case let .failed(error):
            resetState(&state)
            state.error = EquatableError(error)

            return perform { $0.reset() }

        case .didPlayToEnd:
            let isPictureInPictureActive = state.isPictureInPictureActive
            let advances = state.timer != -1 && state.hasNextEpisode

            return .run { [engine] send in
                _ = await engine.seek(to: 0)

                if isPictureInPictureActive {
                    await engine.stopPictureInPicture()
                } else if advances {
                    await send(.nextTrackTapped, animation: .easeInOut(duration: 0.15))
                }
            }

        case let .routesDetected(routesDetected):
            state.routesDetected = routesDetected

            return .none

        case let .pictureInPictureActive(isActive):
            state.isPictureInPictureActive = isActive
            updateNextTimer(&state)

            return .merge(
                showCursor(),
                setMask(!isActive, &state),
                perform { [isVisible = state.isAmbientLightVisible] engine in engine.setAmbientLight(isVisible) }
            )

        case let .pictureInPicturePossible(isPossible):
            state.isPictureInPicturePossible = isPossible

            return .none

        case let .remote(command):
            switch command {
            case .play:
                return perform { [rate = state.rate] engine in engine.play(rate: rate) }
            case .pause:
                return perform { $0.pause() }
            case .togglePlayPause:
                return togglePlayback(state)
            case let .changePosition(position):
                return perform { _ = await $0.seek(to: position) }
            case let .changeRate(rate):
                return .run { _ in Defaults[.rate] = rate }
            case let .skip(interval):
                return skip(by: interval, &state)
            case .previousTrack:
                return .run { send in await send(.previousTrackTapped, animation: .easeInOut(duration: 0.15)) }
            case .nextTrack:
                return .run { send in await send(.nextTrackTapped, animation: .easeInOut(duration: 0.15)) }
            }
        }
    }
}
