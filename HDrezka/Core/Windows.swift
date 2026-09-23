import SwiftUI

enum Windows: String, CaseIterable, Identifiable {
    case hdrezka
    case player
    case imageViewer
    case licenses

    var id: String {
        rawValue
    }

    var window: NSWindow? {
        NSApp.windows.first(where: { $0.identifier?.rawValue.localizedCaseInsensitiveContains(rawValue) ?? false })
    }
}
