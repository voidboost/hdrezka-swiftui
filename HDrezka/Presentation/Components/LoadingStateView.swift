import SwiftUI

struct LoadingStateView: View {
    private let title: String?

    init(_ title: String? = nil) {
        self.title = title
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

            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
