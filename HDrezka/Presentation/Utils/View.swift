import Defaults
import SwiftUI

extension View {
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

    @ViewBuilder func customOnChange<V: Equatable>(of value: V, _ action: @escaping () -> Void) -> some View {
        if #available(macOS 14, *) {
            onChange(of: value) {
                action()
            }
        } else {
            onChange(of: value) { _ in
                action()
            }
        }
    }

    @ViewBuilder func viewModifier<Content: View>(
        @ViewBuilder body: (_ content: Self) -> Content
    ) -> some View {
        body(self)
    }
}
