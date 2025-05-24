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
                                removal: .wipe(reversed: true, blurRadius: 10)
                            )
                        )
                } else {
                    ProgressView()
                        .transition(
                            .asymmetric(
                                insertion: .wipe(blurRadius: 10),
                                removal: .wipe(reversed: true, blurRadius: 10)
                            )
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
        .task {
            guard let window else { return }

            window.isMovableByWindowBackground = true

            if !window.styleMask.contains(.fullScreen) {
                window.toggleFullScreen(nil)
            }
        }
        .ignoresSafeArea()
        .focusable()
        .frame(minWidth: 300 * (16 / 9), maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
        .background(WindowAccessor { window in
            self.window = window
            window.contentView?.focusRingType = .none
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
                        Rectangle()
                            .fill(.gray)
                    }
                }
                .onDisappear(.cancel)
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .clipShape(Rectangle())

                VStack {}
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThickMaterial)
            }
        }
        .contentShape(Rectangle())
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
                )
        )
    }
}
