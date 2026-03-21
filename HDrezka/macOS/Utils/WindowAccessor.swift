import AppKit
import SwiftUI

struct WindowAccessor: NSViewRepresentable {
    @Binding private var window: NSWindow?

    init(window: Binding<NSWindow?>) {
        _window = window
    }

    func makeNSView(context _: Context) -> NSView {
        let view = NSView()

        DispatchQueue.main.async {
            window = view.window
        }

        return view
    }

    func updateNSView(_: NSView, context _: Context) {}
}
