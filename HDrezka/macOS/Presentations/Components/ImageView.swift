import Kingfisher
import SwiftUI

struct ImageView: View {
    private let url: URL

    @Environment(\.dismiss) private var dismiss

    @State private var window: NSWindow?

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
                maxZoomScale: 5,
                doubleTapZoomScale: 3,
            )
            .navigationTitle("key.imageViewer")
            .toolbar(.hidden)
            .frame(minWidth: 300 * (16 / 9), maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
            .ignoresSafeArea()
            .focusable()
            .focusEffectDisabled()
            .contentShape(.rect)
            .background(Color.clear)
            .background(WindowAccessor(window: $window))
            .onChange(of: window) {
                guard let window, !window.styleMask.contains(.fullScreen) else { return }

                window.toggleFullScreen(nil)
            }
            .onExitCommand {
                dismiss()
            }
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
            .gesture(
                WindowDragGesture()
                    .exclusively(before:
                        TapGesture(count: 2)
                            .onEnded {
                                guard let window else { return }

                                window.toggleFullScreen(nil)
                            }
                            .exclusively(before:
                                TapGesture(count: 1)
                                    .onEnded {
                                        dismiss()
                                    })),
            )
            .overlay(alignment: .bottomTrailing) {
                ShareLink(item: url) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.accessoryBar)
                .padding(10)
            }
    }
}
