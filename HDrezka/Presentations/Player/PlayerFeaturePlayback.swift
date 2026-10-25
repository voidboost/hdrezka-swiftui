import ComposableArchitecture
import SQLiteData
import SwiftUI

extension PlayerFeature {
    func setup(_ state: inout State, seek: Double?, isPlaying: Bool) -> Effect<Action> {
        guard let urls = state.movie.getClosestTo(quality: state.quality)?.compactMap(\.hls), !urls.isEmpty else { return .none }

        state.pendingSeek = seek
        state.playsAfterSetup = isPlaying

        let configuration = PlayerEngine.Configuration(
            urls: urls,
            subtitles: state.movie.subtitles,
            title: state.name,
            album: state.voiceActing.name,
            artist: state.season.flatMap { season in state.episode.map { "Season \(season.name) Episode \($0.name)" } },
            poster: state.poster,
            videoGravity: state.videoGravity,
            ambientLight: state.isAmbientLightVisible,
            volume: state.volume,
            isMuted: state.isMuted,
            rate: state.rate
        )

        var effects: [Effect<Action>] = [
            .run { [engine] send in
                let events = await engine.load(configuration)

                for await event in events {
                    await send(.engine(event), animation: event.animation)
                }
            }
            .cancellable(id: CancelID.engine, cancelInFlight: true),
        ]

        if let path = state.movie.thumbnails {
            effects.append(
                .run { send in
                    guard let thumbnails = try? await getMovieThumbnailsUseCase(path: path) else { return }

                    await send(.thumbnailsLoaded(thumbnails))
                }
            )
        }

        return .merge(effects)
    }

    func startPlayback(_ state: State) -> Effect<Action> {
        if let seek = state.pendingSeek {
            return perform { [rate = state.rate, isPlaying = state.playsAfterSetup] engine in
                _ = await engine.seek(to: seek)

                if isPlaying {
                    engine.play(rate: rate)
                }
            }
        }

        return .run { [voiceActing = state.voiceActing, season = state.season, episode = state.episode] send in
            let position = try? await database.read { db in
                try PlayerPosition
                    .where {
                        $0.id.id.eq(voiceActing.voiceId) &&
                            $0.id.acting.eq(voiceActing.translatorId) &&
                            $0.id.season.eq(season?.seasonId ?? "") &&
                            $0.id.episode.eq(episode?.episodeId ?? "")
                    }
                    .fetchOne(db)
            }

            await send(.playbackPositionLoaded(position?.position))
        }
    }

    func switchTrack(to season: MovieSeason, _ episode: MovieEpisode, _ state: inout State) -> Effect<Action> {
        resetState(&state)

        return .run { [engine, voiceActing = state.voiceActing, favs = state.favs] send in
            await engine.reset()

            let result = await Result { try await getMovieVideoUseCase(voiceActing: voiceActing, season: season, episode: episode, favs: favs) }

            await send(.trackLoaded(season, episode, result))
        }
        .cancellable(id: CancelID.track, cancelInFlight: true)
    }

    func resetState(_ state: inout State) {
        state.isReady = false
        state.error = nil
        state.nextTimer = nil
        state.subtitlesOptions = []
        state.isLoading = true
        state.thumbnails = nil
        state.duration = .greatestFiniteMagnitude
        state.currentTime = 0.0
    }

    func togglePlayback(_ state: State) -> Effect<Action> {
        perform { [isPlaying = state.isPlaying, rate = state.rate] engine in
            if isPlaying {
                engine.pause()
            } else {
                engine.play(rate: rate)
            }
        }
    }

    func skip(by interval: Double, _ state: inout State) -> Effect<Action> {
        let target = min(max(state.currentTime + interval, 0.0), state.duration)

        state.currentTime = target

        return perform { [isPlaying = state.isPlaying, rate = state.rate] engine in
            if await engine.seek(to: target), isPlaying {
                engine.play(rate: rate)
            }
        }
    }

    func perform(_ operation: @escaping @MainActor @Sendable (PlayerEngine) async -> Void) -> Effect<Action> {
        .run { [engine] _ in await operation(engine) }
    }
}

private extension PlayerEvent {
    var animation: Animation? {
        switch self {
        case .time, .positionTick, .loadedTimeRanges, .duration, .status, .isMuted, .volume, .remote, .didPlayToEnd:
            nil
        case .timeControlStatus, .routesDetected, .pictureInPicturePossible:
            .easeInOut(duration: 0.15)
        case .failed, .pictureInPictureActive:
            .easeInOut
        }
    }
}
