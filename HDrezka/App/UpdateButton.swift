import Combine
import Sparkle
import SwiftUI

struct UpdateButton: View {
    private let updater: SPUUpdater

    @State private var canCheckForUpdates: Bool = false

    init(updater: SPUUpdater) {
        self.updater = updater
    }

    var body: some View {
        Button {
            updater.checkForUpdates()
        } label: {
            Text("key.checkUpdates")
        }
        .disabled(!canCheckForUpdates)
        .onReceive(updater.publisher(for: \.canCheckForUpdates).receive(on: DispatchQueue.main)) { canCheckForUpdates in
            self.canCheckForUpdates = canCheckForUpdates
        }
    }
}
