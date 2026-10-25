import ComposableArchitecture
import SwiftUI

extension PlayerFeature {
    func setMask(_ isMaskShown: Bool, _ state: inout State) -> Effect<Action> {
        guard !state.isMaskLocked else { return .none }

        state.isMaskShow = isMaskShown

        guard isMaskShown, !state.isLoading, state.isPlaying else { return .cancel(id: CancelID.hideMask) }

        return .run { send in
            try await clock.sleep(for: .seconds(3))

            await send(.hideMaskFired, animation: .easeInOut)
        }
        .cancellable(id: CancelID.hideMask, cancelInFlight: true)
    }

    func resetSleepTimer(_ state: inout State) -> Effect<Action> {
        updateNextTimer(&state)

        guard let timer = state.timer, timer > 0, state.isPlaying else { return .cancel(id: CancelID.sleepTimer) }

        return .run { send in
            try await clock.sleep(for: .seconds(timer))

            await send(.sleepTimerFired)
        }
        .cancellable(id: CancelID.sleepTimer, cancelInFlight: true)
    }

    func updateNextTimer(_ state: inout State) {
        let remaining = (state.duration - state.currentTime) / 60

        if remaining > 0, remaining <= 1, state.hasNextEpisode, state.timer != -1, !state.isPictureInPictureActive {
            state.nextTimer = min(remaining, 1.0)
        } else if state.nextTimer != nil {
            state.nextTimer = nil
        }
    }

    func showCursor(_ isShowed: Bool = true) -> Effect<Action> {
        perform { $0.showCursor(isShowed) }
    }
}
