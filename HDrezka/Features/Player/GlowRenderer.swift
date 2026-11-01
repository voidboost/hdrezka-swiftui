import AVKit

final class GlowRenderer: NSObject, AVPlayerItemOutputPullDelegate, @unchecked Sendable {
    struct Crop {
        var top: Float = 0
        var bottom: Float = 0
        var left: Float = 0
        var right: Float = 0
    }

    struct Frame {
        let image: CGImage
        let size: CGSize
        let crop: Crop
    }

    private static let width = 128
    private static let height = 72
    private static let flickerReduction: Float = 50
    private static let idleInterval: CFTimeInterval = 0.5

    let videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: [
        kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
        kCVPixelBufferWidthKey as String: width,
        kCVPixelBufferHeightKey as String: height,
    ])

    var onFrame: ((Frame) -> Void)?

    private let queue = DispatchQueue(label: "io.silentsea.hdrezka.glowQueue", qos: .userInitiated)
    private let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    private weak var item: AVPlayerItem?
    private var displayLink: CADisplayLink?
    private var lastFrameTimestamp: CFTimeInterval = 0
    private var generation = 0
    private var isRendering = false
    private var smoothed = [Float](repeating: 0, count: width * height * 3)
    private var hasSmoothed = false
    private var letterbox = LetterboxDetector()

    override init() {
        super.init()

        videoOutput.setDelegate(self, queue: .main)
    }

    @MainActor func start(item: AVPlayerItem) {
        self.item = item
        generation += 1

        reset()

        if displayLink == nil {
            displayLink = Windows.player.window?.displayLink(target: self, selector: #selector(step)) ?? NSScreen.main?.displayLink(target: self, selector: #selector(step))
            displayLink?.add(to: .main, forMode: .common)
        }

        wake()
    }

    @MainActor func stop() {
        displayLink?.invalidate()
        displayLink = nil
        item = nil
        generation += 1
    }

    func outputMediaDataWillChange(_: AVPlayerItemOutput) {
        wake()
    }

    func outputSequenceWasFlushed(_: AVPlayerItemOutput) {
        reset()
    }

    private func wake() {
        lastFrameTimestamp = CACurrentMediaTime()
        displayLink?.isPaused = false
    }

    private func reset() {
        queue.async { [self] in
            hasSmoothed = false
            letterbox = LetterboxDetector()
        }
    }

    @objc private func step(_ displayLink: CADisplayLink) {
        let time = videoOutput.itemTime(forHostTime: displayLink.targetTimestamp)

        guard videoOutput.hasNewPixelBuffer(forItemTime: time) else {
            if displayLink.targetTimestamp - lastFrameTimestamp > Self.idleInterval {
                displayLink.isPaused = true
                videoOutput.requestNotificationOfMediaDataChange(withAdvanceInterval: displayLink.duration)
            }

            return
        }

        lastFrameTimestamp = displayLink.targetTimestamp

        guard !isRendering, let size = item?.presentationSize, size.width > 0, size.height > 0 else { return }

        let render: @Sendable () -> Frame?

        if #available(macOS 26.0, *) {
            guard let pixelBuffer = videoOutput.pixelBufferAndDisplayTime(forItemTime: time).pixelBuffer else { return }

            render = { [self] in
                pixelBuffer.withUnsafeBuffer { buffer in
                    makeFrame(from: buffer, size: size)
                }
            }
        } else {
            guard let copiedPixelBuffer = videoOutput.copyPixelBuffer(forItemTime: time, itemTimeForDisplay: nil) else { return }

            nonisolated(unsafe) let pixelBuffer = copiedPixelBuffer

            render = { [self] in
                makeFrame(from: pixelBuffer, size: size)
            }
        }

        let generation = generation

        isRendering = true

        queue.async { [self] in
            let frame = render()

            DispatchQueue.main.async { [self] in
                isRendering = false

                if let frame, generation == self.generation {
                    onFrame?(frame)
                }
            }
        }
    }

    private func makeFrame(from pixelBuffer: CVPixelBuffer, size: CGSize) -> Frame? {
        guard CVPixelBufferGetWidth(pixelBuffer) == Self.width,
              CVPixelBufferGetHeight(pixelBuffer) == Self.height,
              CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly) == kCVReturnSuccess
        else {
            return nil
        }

        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }

        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let pixels = UnsafeRawBufferPointer(start: baseAddress, count: bytesPerRow * Self.height)

        let crop = letterbox.detect(pixels, bytesPerRow: bytesPerRow, width: Self.width, height: Self.height)

        return makeImage(from: pixels, bytesPerRow: bytesPerRow).map { Frame(image: $0, size: size, crop: crop) }
    }

    private func makeImage(from pixels: UnsafeRawBufferPointer, bytesPerRow: Int) -> CGImage? {
        let multiplier = hasSmoothed ? (118 - Self.flickerReduction) / 118 : 1
        var output = Data(repeating: 255, count: Self.width * Self.height * 4)

        smoothed.withUnsafeMutableBufferPointer { smoothed in
            output.withUnsafeMutableBytes { output in
                for y in 0 ..< Self.height {
                    for x in 0 ..< Self.width {
                        let input = y * bytesPerRow + x * 4
                        let index = y * Self.width + x

                        let red = Float(pixels[input + 2]) / 255
                        let green = Float(pixels[input + 1]) / 255
                        let blue = Float(pixels[input]) / 255

                        var percentage: Float = 1

                        if hasSmoothed {
                            let previous = smoothed[index * 3] * 0.213 + smoothed[index * 3 + 1] * 0.715 + smoothed[index * 3 + 2] * 0.072
                            let difference = abs(red * 0.213 + green * 0.715 + blue * 0.072 - previous)

                            percentage = min(1, (1 - difference * difference * difference) * multiplier)
                        }

                        smoothed[index * 3] += (red - smoothed[index * 3]) * percentage
                        smoothed[index * 3 + 1] += (green - smoothed[index * 3 + 1]) * percentage
                        smoothed[index * 3 + 2] += (blue - smoothed[index * 3 + 2]) * percentage

                        output[index * 4] = UInt8(min(max(smoothed[index * 3], 0), 1) * 255)
                        output[index * 4 + 1] = UInt8(min(max(smoothed[index * 3 + 1], 0), 1) * 255)
                        output[index * 4 + 2] = UInt8(min(max(smoothed[index * 3 + 2], 0), 1) * 255)
                    }
                }
            }
        }

        hasSmoothed = true

        guard let provider = CGDataProvider(data: output as CFData) else { return nil }

        return CGImage(
            width: Self.width,
            height: Self.height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: Self.width * 4,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent,
        )
    }
}

private struct LetterboxDetector {
    private let blackThreshold: Float = 20 / 255
    private let historySize = 16
    private let smoothingSpeed: Float = 0.15
    private var current = GlowRenderer.Crop()
    private var target = GlowRenderer.Crop()
    private var history: [GlowRenderer.Crop] = []

    mutating func detect(_ pixels: UnsafeRawBufferPointer, bytesPerRow: Int, width: Int, height: Int) -> GlowRenderer.Crop {
        func luminance(_ x: Int, _ y: Int) -> Float {
            let offset = y * bytesPerRow + x * 4

            return (Float(pixels[offset + 2]) * 0.2126 + Float(pixels[offset + 1]) * 0.7152 + Float(pixels[offset]) * 0.0722) / 255
        }

        func isRowBlack(_ y: Int) -> Bool {
            (0 ..< width).allSatisfy { luminance($0, y) <= blackThreshold }
        }

        func isColumnBlack(_ x: Int) -> Bool {
            (0 ..< height).allSatisfy { luminance(x, $0) <= blackThreshold }
        }

        var centerLuminance: Float = 0

        for y in height / 4 ..< height * 3 / 4 {
            for x in width / 4 ..< width * 3 / 4 {
                centerLuminance += luminance(x, y)
            }
        }

        guard centerLuminance / Float((height / 2) * (width / 2)) > blackThreshold * 1.5 else { return current }

        let maxRows = Int(Float(height) * 0.35)
        let maxColumns = Int(Float(width) * 0.35)

        let top = (0 ..< maxRows).prefix(while: isRowBlack).count
        let bottom = (0 ..< maxRows).prefix { isRowBlack(height - 1 - $0) }.count
        let left = (0 ..< maxColumns).prefix(while: isColumnBlack).count
        let right = (0 ..< maxColumns).prefix { isColumnBlack(width - 1 - $0) }.count

        let vertical = Self.bar(Float(top) / Float(height), Float(bottom) / Float(height))
        let horizontal = Self.bar(Float(left) / Float(width), Float(right) / Float(width))

        let candidate = GlowRenderer.Crop(top: vertical, bottom: vertical, left: horizontal, right: horizontal)

        if history.count >= historySize {
            history.removeFirst()
        }

        history.append(candidate)

        func isSimilar(_ lhs: GlowRenderer.Crop, _ rhs: GlowRenderer.Crop) -> Bool {
            abs(lhs.top - rhs.top) < 0.03 && abs(lhs.left - rhs.left) < 0.03
        }

        let matches = history.map { crop in history.count { isSimilar(crop, $0) } }

        if let index = matches.indices.max(by: { matches[$0] < matches[$1] }), matches[index] >= historySize / 2 {
            target = history[index]
        }

        current = GlowRenderer.Crop(
            top: Self.lerp(current.top, target.top, smoothingSpeed),
            bottom: Self.lerp(current.bottom, target.bottom, smoothingSpeed),
            left: Self.lerp(current.left, target.left, smoothingSpeed),
            right: Self.lerp(current.right, target.right, smoothingSpeed),
        )

        return current
    }

    private static func bar(_ lhs: Float, _ rhs: Float) -> Float {
        let size = (lhs + rhs) / 2

        return abs(lhs - rhs) > 0.08 || size < 0.03 ? 0 : size
    }

    private static func lerp(_ start: Float, _ stop: Float, _ amount: Float) -> Float {
        abs(stop - start) < 0.002 ? stop : start + (stop - start) * amount
    }
}
