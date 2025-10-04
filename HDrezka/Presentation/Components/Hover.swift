import Foundation
import SwiftUI

struct HighlightOnHover: ViewModifier {
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .contentShape(.rect(cornerRadius: 6))
            .background(isHovered ? Color.gray.opacity(0.1) : Color.clear, in: .rect(cornerRadius: 6))
            .onHover { isHovered in
                withAnimation {
                    self.isHovered = isHovered
                }
            }
    }
}

extension View {
    func highlightOnHover() -> some View {
        modifier(HighlightOnHover())
    }
}
