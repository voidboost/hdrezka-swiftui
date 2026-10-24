import ComposableArchitecture
import SwiftUI

extension Send {
    func callAsFunction(_ action: Action, awaitingAnimation animation: Animation) async {
        await withCheckedContinuation { continuation in
            var transaction = Transaction(animation: animation)
            transaction.addAnimationCompletion {
                continuation.resume()
            }

            self(action, transaction: transaction)
        }
    }
}
