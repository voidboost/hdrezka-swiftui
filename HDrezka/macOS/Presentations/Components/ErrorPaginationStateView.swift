import SwiftUI

struct ErrorPaginationStateView: View {
    private let error: Error
    private let retryAction: () -> Void

    init(_ error: Error, _ retryAction: @escaping () -> Void) {
        self.error = error
        self.retryAction = retryAction
    }

    var body: some View {
        HStack {
            Spacer()

            VStack(alignment: .center) {
                Text(error.localizedDescription)
                    .lineLimit(nil)
                    .multilineTextAlignment(.center)

                Button {
                    retryAction()
                } label: {
                    Text("key.retry")
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.accessoryBar)
            }

            Spacer()
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 36)
    }
}
