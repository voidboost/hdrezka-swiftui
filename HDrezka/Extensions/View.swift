import Defaults
import SwiftUI

extension View {
    func imageFill(
        _ ratio: CGFloat? = nil
    ) -> some View {
        aspectRatio(contentMode: .fill)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .aspectRatio(ratio, contentMode: .fit)
    }

    func viewModifier(
        @ViewBuilder body: (_ content: Self) -> some View
    ) -> some View {
        body(self)
    }

    func cardStyle() -> some View {
        background(.quinary, in: .rect(cornerRadius: 6))
            .overlay(.tertiary, in: .rect(cornerRadius: 6).stroke(lineWidth: 1))
    }
}

extension View {
    func onScrollNearEnd<Item: Identifiable>(
        of items: [Item]?,
        threshold: Int = 1,
        isEnabled: Bool,
        perform action: @escaping () -> Void
    ) -> some View {
        onScrollTargetVisibilityChange(idType: Item.ID.self) { visibleIds in
            if isEnabled, let items, items.suffix(threshold).contains(where: { visibleIds.contains($0.id) }) {
                action()
            }
        }
    }
}
