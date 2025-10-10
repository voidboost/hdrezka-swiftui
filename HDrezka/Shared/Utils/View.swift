import Defaults
import SwiftUI

extension View {
    @ViewBuilder func imageFill(
        _ ratio: CGFloat? = nil,
    ) -> some View {
        aspectRatio(contentMode: .fill)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .aspectRatio(ratio, contentMode: .fit)
    }

    @ViewBuilder func viewModifier(
        @ViewBuilder body: (_ content: Self) -> some View,
    ) -> some View {
        body(self)
    }
}
