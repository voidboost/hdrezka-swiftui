import SwiftUI

struct ErrorStateView: View {
    private let title: String?
    private let error: Error
    private let retryAction: () -> Void

    init(_ error: Error, _ title: String? = nil, _ retryAction: @escaping () -> Void) {
        self.title = title
        self.error = error
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
                Text(error.localizedDescription)
                    .font(.system(size: 20, weight: .medium))
                    .lineLimit(nil)
                    .multilineTextAlignment(.center)

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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
