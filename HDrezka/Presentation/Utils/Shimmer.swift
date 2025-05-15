import SwiftUI

struct Shimmer: ViewModifier {
    @State private var isInitialState = true

    func body(content: Content) -> some View {
        content
            .mask(
                LinearGradient(
                    colors: [
                        .black.opacity(0.3),
                        .black,
                        .black.opacity(0.3)
                    ],
                    startPoint: isInitialState ? UnitPoint(x: -0.3, y: -0.3) : UnitPoint(x: 1, y: 1),
                    endPoint: isInitialState ? UnitPoint(x: 0, y: 0) : UnitPoint(x: 1.3, y: 1.3)
                )
            )
            .task {
                withAnimation(.linear(duration: 1.5).delay(0.25).repeatForever(autoreverses: false)) {
                    isInitialState = false
                }
            }
    }
}

extension View {
    @ViewBuilder func shimmering(active: Bool = true) -> some View {
        if active {
            modifier(Shimmer())
        } else {
            self
        }
    }
}
