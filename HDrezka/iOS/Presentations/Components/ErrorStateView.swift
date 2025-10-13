import SwiftUI

struct ErrorStateView: View {
    private let error: Error
    private let retryAction: () -> Void

    init(_ error: Error, _ retryAction: @escaping () -> Void) {
        self.error = error
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(error.localizedDescription)
                .font(.system(.title, weight: .medium))
                .lineLimit(nil)
                .multilineTextAlignment(.center)

            Button {
                retryAction()
            } label: {
                Text("key.retry")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
            }
            .buttonStyle(.bordered)
            .keyboardShortcut("r", modifiers: .command)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
