import SwiftUI

struct PersonInfoRowView: View {
    private let title: String
    private let info: String

    init(_ title: String, _ info: String) {
        self.title = title
        self.info = info
    }

    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.body)

            Spacer()

            Text(info)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 8)
    }
}
