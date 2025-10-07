import SwiftUI

struct ImageView: View {
    private let url: URL

    @Environment(\.dismiss) private var dismiss

    @State private var window: NSWindow?

    init(url: URL) {
        self.url = url
    }

    var body: some View {
        ZStack(alignment: .center) {
            AsyncImage(url: url, transaction: .init(animation: .easeInOut)) { phase in
                if let image = phase.image {
                    image.resizable()
                } else {
                    ProgressView()
                }
            }
            .scaledToFit()

            VStack {
                Spacer()

                HStack {
                    Spacer()

                    ShareLink(item: url) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .buttonStyle(.accessoryBar)
                }
                .padding(10)
            }
        }
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
            ZStack(alignment: .topLeading) {
                AsyncImage(url: url, transaction: .init(animation: .easeInOut)) { phase in
                    if let image = phase.image {
                        image.resizable()
                    } else {
                        Color.gray
                    }
                }
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack {}
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThickMaterial)
            }
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
