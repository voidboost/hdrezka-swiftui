import Defaults
import SwiftUI

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    @ViewBuilder func ifLet<T, Content: View>(_ value: T?, _ condition: Bool = true, transform: (Self, T) -> Content) -> some View {
        if let value, condition {
            transform(self, value)
        } else {
            self
        }
    }

    @ViewBuilder func imageFill(
        _ ratio: CGFloat? = nil
    ) -> some View {
        aspectRatio(contentMode: .fill)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .aspectRatio(ratio, contentMode: .fit)
    }

    @ViewBuilder func load<T: Equatable>(_ id: T, _ block: @escaping () -> Void) -> some View {
        task(id: id) {
            if Defaults[.navigationAnimation] {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    block()
                }
            } else {
                block()
            }
        }
    }
}
