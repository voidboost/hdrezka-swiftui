import SwiftUI

struct LoadingPaginationStateView: View {
    var body: some View {
        HStack(alignment: .center) {
            Spacer()

            ProgressView()

            Spacer()
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 36)
    }
}
