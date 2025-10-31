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
                minZoomScale: 1,
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
            .background(WindowAccessor { window in
                self.window = window
                if !window.styleMask.contains(.fullScreen) {
                    window.toggleFullScreen(nil)
                }
            })
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
            .overlay(alignment: .bottomTrailing) {
                ShareLink(item: url) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.accessoryBar)
                .padding(10)
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
    }
}
