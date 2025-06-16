import AVFoundation
import SwiftUI

struct SliderWithText<T: BinaryFloatingPoint>: View {
    @Binding var value: T
    let inRange: ClosedRange<T>
    let buffers: [CMTimeRange]
    let activeFillColor: Color
    let fillColor: Color
    let emptyColor: Color
    let height: Double
    let thumbnails: WebVTT?
    let onEditingChanged: (Bool) -> Void

    @State private var localRealProgress: T = 0
    @State private var localTempProgress: T = 0
    @GestureState private var isActive: Bool = false
    @State private var progressDuration: T = 0

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
        onEditingChanged: @escaping (Bool) -> Void
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

    var body: some View {
        ZStack(alignment: .center) {
            VStack {
                GeometryReader { geometry in
                    ZStack(alignment: .center) {
                        emptyColor
                        (isActive ? activeFillColor : fillColor)
                            .mask {
                                HStack {
                                    Color.black
                                        .frame(width: max(geometry.size.width * CGFloat(localRealProgress + localTempProgress), 0), alignment: .leading)
                                    Spacer(minLength: 0)
                                }
                            }

                        ForEach(buffers, id: \.self) { buffer in
                            if let start = buffer.start.seconds as? T, let end = buffer.end.seconds as? T {
                                emptyColor
                                    .mask {
                                        ZStack(alignment: .topLeading) {
                                            let duration = if isActive {
                                                max(Double(end / inRange.upperBound) - Double(start / inRange.upperBound), 0)
                                            } else {
                                                max(Double(end / inRange.upperBound) - Double(localRealProgress + localTempProgress), 0)
                                            }

                                            let point = CGPoint(
                                                x: isActive ? max(geometry.size.width * (Double(start / inRange.upperBound) + duration * 0.5), 0) : max(geometry.size.width * (Double(localRealProgress + localTempProgress) + duration * 0.5), 0),
                                                y: (isActive ? height * 1.25 : height) * 0.5,
                                            )

                                            Color.black
                                                .frame(width: max(geometry.size.width * duration, 0))
                                                .position(x: point.x, y: point.y)
                                        }
                                    }
                            }
                        }
                    }
                    .frame(height: isActive ? height * 1.25 : height, alignment: .center)
                    .animation(.easeInOut, value: isActive)
                    .clipShape(.capsule)
                    .contentShape(.capsule)
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .local)
                            .updating($isActive) { _, state, _ in
                                state = true
                            }
                            .onChanged { gesture in
                                localRealProgress = max(min(T(gesture.location.x / geometry.size.width), 1), 0)
                                let prg = max(min(localRealProgress + localTempProgress, 1), 0)
                                progressDuration = inRange.upperBound * prg
                                value = max(min(getPrgValue(), inRange.upperBound), inRange.lowerBound)

                                withAnimation(.easeInOut) {
                                    unitSeekImage = gesture.location.x / geometry.size.width
                                }
                            }.onEnded { _ in
                                localRealProgress = max(min(localRealProgress + localTempProgress, 1), 0)
                                localTempProgress = 0
                                progressDuration = inRange.upperBound * localRealProgress
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
                        if showSeekImage || isActive, let cue = thumbnails?.cues.first(where: { TimeInterval(unitSeekImage) * TimeInterval(inRange.upperBound) > $0.timeStart && TimeInterval(unitSeekImage) * TimeInterval(inRange.upperBound) < $0.timeEnd }), let imageUrl = cue.imageUrl, let frame = cue.frame {
                            ZStack {
                                AsyncImage(url: URL(string: imageUrl), transaction: .init(animation: .easeInOut)) { phase in
                                    if let image = phase.image, let nsImage = ImageRenderer(content: image).cgImage?.crop(to: frame) {
                                        Image(nsImage: nsImage).resizable()
                                    } else {
                                        ProgressView().scaleEffect(0.75)
                                    }
                                }
                                .scaledToFill()
                                .frame(width: frame.width, height: frame.height)
                                .background(.ultraThinMaterial)
                                .clipShape(.rect(cornerRadius: 6))
                                .overlay(.ultraThinMaterial, in: .rect(cornerRadius: 6).stroke(lineWidth: 1))
                                .overlay {
                                    VStack {
                                        Spacer()

                                        HStack {
                                            Spacer()
                                            Text((T(Float(unitSeekImage)) * inRange.upperBound).asTimeString(style: .positional))
                                                .font(.system(size: 9))
                                                .foregroundStyle(.secondary)
                                            Spacer()
                                        }
                                    }
                                    .padding(3)
                                }
                                .position(x: min(max(unitSeekImage * geometry.size.width, frame.width * 0.5), geometry.size.width - frame.width * 0.5), y: -(frame.height * 0.5) - 6)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }

                HStack {
                    Text(progressDuration.asTimeString(style: .positional))
                    Spacer(minLength: 0)
                    Text("-" + (inRange.upperBound - progressDuration).asTimeString(style: .positional))
                }
                .font(.system(size: 11).monospacedDigit())
                .foregroundColor(isActive ? fillColor : emptyColor)
            }
        }
        .frame(maxWidth: .infinity)
        .onChange(of: isActive) {
            value = max(min(getPrgValue(), inRange.upperBound), inRange.lowerBound)
            onEditingChanged(isActive)
        }
        .task {
            localRealProgress = getPrgPercentage(value)
            progressDuration = inRange.upperBound * localRealProgress
        }
        .onChange(of: value) {
            if !isActive {
                localRealProgress = getPrgPercentage(value)
                progressDuration = inRange.upperBound * localRealProgress
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

extension BinaryFloatingPoint {
    func asTimeString(style: DateComponentsFormatter.UnitsStyle) -> String {
        let formatter = DateComponentsFormatter()
        if self < 3600 {
            formatter.allowedUnits = [.minute, .second]
        } else {
            formatter.allowedUnits = [.hour, .minute, .second]
        }
        formatter.unitsStyle = style
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: TimeInterval(self)) ?? ""
    }
}

private extension CGImage {
    func crop(to rect: CGRect) -> NSImage? {
        guard let cutImageRef = cropping(to: rect) else { return nil }

        return NSImage(cgImage: cutImageRef, size: .init(width: CGFloat(cutImageRef.width), height: CGFloat(cutImageRef.height)))
    }
}
