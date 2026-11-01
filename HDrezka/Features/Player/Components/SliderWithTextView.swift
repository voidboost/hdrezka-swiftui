import AVFoundation
import Kingfisher
import SwiftUI

struct SliderWithTextView<T: BinaryFloatingPoint>: View {
    @Binding var value: T
    let inRange: ClosedRange<T>
    let buffers: [CMTimeRange]
    let activeFillColor: Color
    let fillColor: Color
    let emptyColor: Color
    let height: Double
    let thumbnails: WebVTT?
    let onEditingChanged: (Bool) -> Void

    @State private var dragProgress: T?
    @GestureState private var isActive: Bool = false

    @State private var showSeekImage: Bool = false
    @State private var unitSeekImage: CGFloat = .zero

    init(
        value: Binding<T>,
        inRange: ClosedRange<T>,
        buffers: [CMTimeRange],
        activeFillColor: Color,
        fillColor: Color,
        emptyColor: Color,
        height: Double,
        thumbnails: WebVTT?,
        onEditingChanged: @escaping (Bool) -> Void = { _ in },
    ) {
        _value = value
        self.inRange = inRange
        self.buffers = buffers
        self.activeFillColor = activeFillColor
        self.fillColor = fillColor
        self.emptyColor = emptyColor
        self.height = height
        self.thumbnails = thumbnails
        self.onEditingChanged = onEditingChanged
    }

    private var progress: T {
        dragProgress ?? getPrgPercentage(value)
    }

    var body: some View {
        let progress = self.progress

        ZStack(alignment: .center) {
            VStack {
                GeometryReader { geometry in
                    ZStack(alignment: .center) {
                        emptyColor
                        (isActive ? activeFillColor : fillColor)
                            .mask(alignment: .leading) {
                                Color.black.frame(width: max(geometry.size.width * CGFloat(progress), 0))
                            }

                        ForEach(buffers, id: \.self) { buffer in
                            if let start = buffer.start.seconds as? T, let end = buffer.end.seconds as? T {
                                emptyColor
                                    .mask(alignment: .leading) {
                                        let duration = if isActive {
                                            max(Double(end / inRange.upperBound) - Double(start / inRange.upperBound), 0)
                                        } else {
                                            max(Double(end / inRange.upperBound) - Double(progress), 0)
                                        }

                                        let point = CGPoint(
                                            x: isActive ? max(geometry.size.width * (Double(start / inRange.upperBound) + duration * 0.5), 0) : max(geometry.size.width * (Double(progress) + duration * 0.5), 0),
                                            y: (isActive ? height * 1.25 : height) * 0.5,
                                        )

                                        Color.black
                                            .frame(width: max(geometry.size.width * duration, 0))
                                            .position(x: point.x, y: point.y)
                                    }
                            }
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
                                dragProgress = max(min(T(gesture.location.x / geometry.size.width), 1), 0)
                                value = max(min(getPrgValue(), inRange.upperBound), inRange.lowerBound)

                                withAnimation(.easeInOut) {
                                    unitSeekImage = gesture.location.x / geometry.size.width
                                }
                            },
                    )
                    .onContinuousHover { phase in
                        switch phase {
                        case let .active(location):
                            unitSeekImage = location.x / geometry.size.width

                            withAnimation(.easeInOut) {
                                showSeekImage = true
                            }
                        case .ended:
                            withAnimation(.easeInOut) {
                                showSeekImage = false
                            }
                        }
                    }
                    .overlay {
                        if showSeekImage || isActive, let cue = thumbnails?.cue(at: TimeInterval(unitSeekImage) * TimeInterval(inRange.upperBound)), let imageUrl = cue.imageUrl, let frame = cue.frame {
                            KFImage
                                .url(URL(string: imageUrl))
                                .placeholder {
                                    ProgressView().scaleEffect(0.75)
                                }
                                .resizable()
                                .cropping(rect: frame)
                                .loadTransition(.blurReplace(.downUp), animation: .bouncy)
                                .cancelOnDisappear(true)
                                .retry(NetworkRetryStrategy())
                                .scaledToFill()
                                .frame(width: frame.width, height: frame.height)
                                .clipShape(.rect(cornerRadius: 6))
                                .background(.ultraThickMaterial, in: .rect(cornerRadius: 6))
                                .overlay(.ultraThickMaterial, in: .rect(cornerRadius: 6).stroke(lineWidth: 1))
                                .overlay(alignment: .bottom) {
                                    Text((T(Float(unitSeekImage)) * inRange.upperBound).asTimeString)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .padding(3)
                                }
                                .position(x: min(max(unitSeekImage * geometry.size.width, frame.width * 0.5), geometry.size.width - frame.width * 0.5), y: -(frame.height * 0.5) - 6)
                        }
                    }
                }

                HStack {
                    Text((inRange.upperBound * progress).asTimeString)
                    Spacer(minLength: 0)
                    Text("-" + (inRange.upperBound - inRange.upperBound * progress).asTimeString)
                }
                .font(.caption.monospacedDigit())
                .foregroundColor(isActive ? fillColor : emptyColor)
            }
        }
        .frame(maxWidth: .infinity)
        .onChange(of: isActive) {
            value = max(min(getPrgValue(), inRange.upperBound), inRange.lowerBound)
            onEditingChanged(isActive)
        }
        .onChange(of: value) {
            if !isActive, dragProgress != nil {
                dragProgress = nil
            }
        }
    }

    private func getPrgPercentage(_ value: T) -> T {
        let range = inRange.upperBound - inRange.lowerBound
        let correctedStartValue = value - inRange.lowerBound
        return correctedStartValue / range
    }

    private func getPrgValue() -> T {
        (progress * (inRange.upperBound - inRange.lowerBound)) + inRange.lowerBound
    }
}

private enum TimeFormatters {
    static let minutes = make([.minute, .second])
    static let hours = make([.hour, .minute, .second])

    private static func make(_ units: NSCalendar.Unit) -> DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = units
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }
}

extension BinaryFloatingPoint {
    var asTimeString: String {
        (self < 3600 ? TimeFormatters.minutes : TimeFormatters.hours).string(from: TimeInterval(self)) ?? ""
    }
}
