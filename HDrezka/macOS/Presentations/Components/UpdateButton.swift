import Combine
import Sparkle
import SwiftUI

struct UpdateButton: View {
    private let updater: SPUUpdater

    @State private var canCheckForUpdates: Bool = false

    @State private var subscriptions: Set<AnyCancellable> = []

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
        .onAppear {
            updater.publisher(for: \.canCheckForUpdates)
                .receive(on: DispatchQueue.main)
                .sink { canCheckForUpdates in
                    self.canCheckForUpdates = canCheckForUpdates
                }
                .store(in: &subscriptions)
        }
    }
}
