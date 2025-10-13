import SwiftUI

struct EmptyStateView: View {
    private let description: String
    private let subdescription: String?
    private let retryAction: (() -> Void)?

    init(_ description: String, _ subdescription: String? = nil, _ retryAction: (() -> Void)? = nil) {
        self.description = description
        self.subdescription = subdescription
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(description)
                .font(.system(.title, weight: .medium))
                .lineLimit(nil)
                .multilineTextAlignment(.center)

            if let subdescription {
                Text(subdescription)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .lineLimit(nil)
                    .multilineTextAlignment(.center)
            }

            if let retryAction {
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
