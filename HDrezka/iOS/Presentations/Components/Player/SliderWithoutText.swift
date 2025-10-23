import SwiftUI

struct SliderWithoutText<T: BinaryFloatingPoint>: View {
    @Binding var value: T
    let inRange: ClosedRange<T>
    let activeFillColor: Color
    let fillColor: Color
    let emptyColor: Color
    let height: CGFloat
    let onEditingChanged: (Bool) -> Void

    @State private var localRealProgress: T = 0
    @State private var localTempProgress: T = 0
    @GestureState private var isActive: Bool = false

    init(
        value: Binding<T>,
        inRange: ClosedRange<T>,
        activeFillColor: Color,
        fillColor: Color,
        emptyColor: Color,
        height: CGFloat,
        onEditingChanged: @escaping (Bool) -> Void = { _ in },
    ) {
        _value = value
        self.inRange = inRange
        self.activeFillColor = activeFillColor
        self.fillColor = fillColor
        self.emptyColor = emptyColor
        self.height = height
        self.onEditingChanged = onEditingChanged
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                ZStack(alignment: .center) {
                    emptyColor
                    (isActive ? activeFillColor : fillColor)
                        .mask(alignment: .leading) {
                            Color.black
                                .frame(width: max(geometry.size.width * CGFloat(localRealProgress + localTempProgress), 0))
                        }
                }
                .frame(height: isActive ? height * 1.25 : height, alignment: .center)
                .animation(.easeInOut, value: isActive)
                .contentShape(.capsule)
                .clipShape(.capsule)
                .highPriorityGesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .updating($isActive) { _, state, _ in
                            state = true
                        }
                        .onChanged { gesture in
                            localTempProgress = T(gesture.translation.width / geometry.size.width)
                            value = max(min(getPrgValue(), inRange.upperBound), inRange.lowerBound)
                        }.onEnded { _ in
                            localRealProgress = max(min(localRealProgress + localTempProgress, 1), 0)
                            localTempProgress = 0
                        },
                )
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onChange(of: isActive) {
                value = max(min(getPrgValue(), inRange.upperBound), inRange.lowerBound)
                onEditingChanged(isActive)
            }
            .onAppear {
                localRealProgress = getPrgPercentage(value)
            }
            .onChange(of: value) {
                if !isActive {
                    localRealProgress = getPrgPercentage(value)
                }
            }
        }
    }

    private func getPrgPercentage(_ value: T) -> T {
        let range = inRange.upperBound - inRange.lowerBound
        let correctedStartValue = value - inRange.lowerBound
        let percentage = correctedStartValue / range
        return percentage
    }

    private func getPrgValue() -> T {
        ((localRealProgress + localTempProgress) * (inRange.upperBound - inRange.lowerBound)) + inRange.lowerBound
    }
}
