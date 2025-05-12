import SwiftUI

struct EmptyStateView: View {
    private let title: String?
    private let description: String
    private let subdescription: String?
    private let retryAction: (() -> Void)?

    init(_ description: String, _ title: String? = nil, _ subdescription: String? = nil, _ retryAction: (() -> Void)? = nil) {
        self.title = title
        self.description = description
        self.subdescription = subdescription
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: 18) {
            if let title {
                VStack(alignment: .leading) {
                    Spacer()

                    Text(title)
                        .font(.largeTitle.weight(.semibold))
                        .lineLimit(1)

                    Spacer()

                    Divider()
                }
                .frame(height: 52)
            }

            VStack(alignment: .center, spacing: 8) {
                Text(description)
                    .font(.system(size: 20, weight: .medium))
                    .lineLimit(nil)
                    .multilineTextAlignment(.center)

                if let subdescription {
                    Text(subdescription)
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .lineLimit(nil)
                        .multilineTextAlignment(.center)
                }

                if let retryAction {
                    Button {
                        retryAction()
                    } label: {
                        Text("key.retry")
                            .font(.system(size: 15))
                            .foregroundStyle(.accent)
                            .highlightOnHover()
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut("r", modifiers: .command)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
