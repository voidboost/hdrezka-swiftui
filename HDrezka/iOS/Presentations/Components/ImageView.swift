import Kingfisher
import SwiftUI

struct ImageView: View {
    private let url: URL

    @Environment(\.dismiss) private var dismiss

    init(url: URL) {
        self.url = url
    }

    var body: some View {
        KFImage
            .url(url)
            .placeholder {
                ProgressView()
            }
            .resizable()
            .loadTransition(.blurReplace, animation: .easeInOut)
            .cancelOnDisappear(true)
            .retry(NetworkRetryStrategy())
            .scaledToFit()
            .zoomable(
                minZoomScale: 1,
                maxZoomScale: 5,
                doubleTapZoomScale: 3,
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(.rect)
            .background {
                KFImage
                    .url(url)
                    .placeholder {
                        Color.gray
                    }
                    .resizable()
                    .loadTransition(.opacity, animation: .easeInOut)
                    .cancelOnDisappear(true)
                    .retry(NetworkRetryStrategy())
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Rectangle().fill(.ultraThickMaterial)
            }
            .overlay(alignment: .topLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.bordered)
                .padding(10)
            }
            .overlay(alignment: .bottomTrailing) {
                ShareLink(item: url) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.bordered)
                .padding(10)
            }
            .gesture(
                TapGesture(count: 1)
                    .onEnded {
                        dismiss()
                    },
            )
    }
}
