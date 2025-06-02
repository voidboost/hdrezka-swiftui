import SwiftUI

extension NSImage {
    func resized(to size: CGSize) -> NSImage {
        let image = self
        image.size = size
        return image
    }

    func tint(_ tint: NSColor) -> NSImage {
        guard isTemplate,
              let tinted = copy() as? NSImage
        else {
            return self
        }

        tinted.lockFocus()
        tint.set()
        CGRect(origin: .zero, size: tinted.size).fill(using: .sourceAtop)
        tinted.unlockFocus()

        return tinted
    }
}
