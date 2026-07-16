import Defaults
import SwiftUI

extension View {
    func imageFill(
        _ ratio: CGFloat? = nil,
    ) -> some View {
        aspectRatio(contentMode: .fill)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .aspectRatio(ratio, contentMode: .fit)
    }

    func viewModifier(
        @ContentBuilder body: (_ content: Self) -> some View,
    ) -> some View {
        body(self)
    }
}
