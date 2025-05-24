import SwiftUI

func dismissWindow(id: String) {
    NSApplication.shared.windows.first { window in window.identifier?.rawValue == id }?.close()
}
