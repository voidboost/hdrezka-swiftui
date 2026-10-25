import ComposableArchitecture
import Defaults
import SwiftUI

extension PlayerFeature {
    func handle(_ change: DefaultsChange, _ state: inout State) -> Effect<Action> {
        switch change {
        case let .rate(rate):
            state.rate = rate

            return perform { [isPlaying = state.isPlaying] engine in engine.setRate(rate, isPlaying: isPlaying) }

        case let .isMuted(isMuted):
            state.isMuted = isMuted

            return .none

        case let .volume(volume):
            state.volume = volume

            return .none

        case let .spatialAudio(spatialAudio):
            return perform { $0.setSpatialAudio(spatialAudio) }

        case let .playerFullscreen(playerFullscreen):
            state.playerFullscreen = playerFullscreen

            return .none

        case let .videoGravity(videoGravity):
            state.videoGravity = videoGravity

            return perform { [isVisible = state.isAmbientLightVisible] engine in
                engine.setAmbientLight(isVisible)
                engine.setVideoGravity(videoGravity)
            }

        case let .ambientLight(ambientLight):
            state.ambientLight = ambientLight

            return perform { [isVisible = state.isAmbientLightVisible] engine in engine.setAmbientLight(isVisible) }

        case let .mediaControlButtonIsSeeking(isSeeking):
            state.mediaControlButtonIsSeeking = isSeeking

            guard state.isReady else { return .none }

            return perform { [mode = state.trackCommandMode] engine in engine.configureTrackCommands(mode) }
        }
    }

    func observeDefaults() -> Effect<Action> {
        .run { send in
            await withTaskGroup(of: Void.self) { group in
                group.addTask { for await value in Defaults.updates(.rate, initial: false) { await send(.defaultsChanged(.rate(value))) } }
                group.addTask { for await value in Defaults.updates(.isMuted, initial: false) { await send(.defaultsChanged(.isMuted(value)), animation: .easeInOut(duration: 0.15)) } }
                group.addTask { for await value in Defaults.updates(.volume, initial: false) { await send(.defaultsChanged(.volume(value)), animation: .easeInOut(duration: 0.15)) } }
                group.addTask { for await value in Defaults.updates(.spatialAudio, initial: false) { await send(.defaultsChanged(.spatialAudio(value))) } }
                group.addTask { for await value in Defaults.updates(.playerFullscreen, initial: false) { await send(.defaultsChanged(.playerFullscreen(value))) } }
                group.addTask { for await value in Defaults.updates(.videoGravity, initial: false) { await send(.defaultsChanged(.videoGravity(value))) } }
                group.addTask { for await value in Defaults.updates(.ambientLight, initial: false) { await send(.defaultsChanged(.ambientLight(value))) } }
                group.addTask { for await value in Defaults.updates(.mediaControlButtonIsSeeking, initial: false) { await send(.defaultsChanged(.mediaControlButtonIsSeeking(value))) } }
            }
        }
        .cancellable(id: CancelID.defaults, cancelInFlight: true)
    }
}
