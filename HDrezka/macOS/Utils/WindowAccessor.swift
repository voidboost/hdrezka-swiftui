import SwiftUI

struct WindowAccessor: NSViewRepresentable {
    private let callback: (NSWindow) -> Void

    init(callback: @escaping (NSWindow) -> Void) {
        self.callback = callback
    }

    func makeNSView(context _: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                callback(window)
            }
        }
        return view
    }

    func updateNSView(_: NSView, context _: Context) {}
}
