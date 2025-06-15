import NukeUI
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
            LazyImage(url: url, transaction: .init(animation: .easeInOut)) { state in
                if let image = state.image {
                    image.resizable()
                        .transition(
                            .asymmetric(
                                insertion: .wipe(blurRadius: 10),
                                removal: .wipe(reversed: true, blurRadius: 10),
                            ),
                        )
                } else {
                    ProgressView()
                        .transition(
                            .asymmetric(
                                insertion: .wipe(blurRadius: 10),
                                removal: .wipe(reversed: true, blurRadius: 10),
                            ),
                        )
                }
            }
            .onDisappear(.cancel)
            .scaledToFit()

            VStack {
                Spacer()

                HStack {
                    Spacer()

                    CustomShareLink(items: [url]) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .buttonStyle(NavbarButtonStyle(width: 30, height: 22))
                }
                .padding(10)
            }
        }
        .navigationTitle("key.imageViewer")
        .ignoresSafeArea()
        .focusable()
        .viewModifier { view in
            if #available(macOS 14, *) {
                view.focusEffectDisabled()
            } else {
                view
            }
        }
        .frame(minWidth: 300 * (16 / 9), maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
        .background(WindowAccessor { window in
            self.window = window

            window.isMovableByWindowBackground = true

            if #unavailable(macOS 14) {
                window.contentView?.focusRingType = .none
            }

            if !window.styleMask.contains(.fullScreen) {
                window.toggleFullScreen(nil)
            }
        })
        .onExitCommand {
            dismiss()
        }
        .background {
            ZStack(alignment: .topLeading) {
                LazyImage(url: url, transaction: .init(animation: .easeInOut)) { state in
                    if let image = state.image {
                        image.resizable()
                    } else {
                        Color.gray
                    }
                }
                .onDisappear(.cancel)
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .clipShape(.rect)

                VStack {}
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThickMaterial)
            }
        }
        .contentShape(.rect)
        .toolbar(.hidden)
        .gesture(
            DragGesture()
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
                                }
                        )
                ),
        )
    }
}
