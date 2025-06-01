import SwiftUI

struct LoadingPaginationStateView: View {
    var body: some View {
        HStack(alignment: .center) {
            Spacer()

            ProgressView()

            Spacer()
        }
        .padding(10)
    }
}
