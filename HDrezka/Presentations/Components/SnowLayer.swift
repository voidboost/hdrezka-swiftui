import simd

final class SnowLayer {
    private static let kernel: [Float] = [0.0625, 0.25, 0.375, 0.25, 0.0625]
    private static let relaxReach = 8

    let opensAtEdges: Bool
    var origin: SIMD2<Float>
    var previousBaseY: Float
    var spill: (left: Float, right: Float) = (0, 0)

    private(set) var heights: [Float]
    private(set) var bed: [Float]
    private(set) var visible: [Bool]
    private(set) var top: Float = 0
    private(set) var bedDepth: Float = 0
    private(set) var isVisible = true

    private let columnWidth = SnowSimulation.columnWidth
    private let depth: Float
    private let phases: (Float, Float)
    private var capacity: [Float] = []
    private var cornerRadius: Float = 0
    private var supported: [Bool]
    private var supportedRange: ClosedRange<Int>?
    private var parity = false
    private var dirtyLower = 0
    private var dirtyUpper = -1
    private var rendered: [Float] = []

    init(origin: SIMD2<Float>, columns: Int, depth: Float, opensAtEdges: Bool, phases: (Float, Float)) {
        self.origin = origin
        self.depth = depth
        self.opensAtEdges = opensAtEdges
        self.phases = phases
        previousBaseY = origin.y
        heights = Array(repeating: 0, count: columns)
        bed = Array(repeating: 0, count: columns)
        visible = Array(repeating: true, count: columns)
        supported = Array(repeating: false, count: columns)
        updateCapacity()
    }

    var count: Int {
        heights.count
    }

    var width: Float {
        Float(heights.count) * columnWidth
    }

    func index(at x: Float) -> Int? {
        let i = Int(((x - origin.x) / columnWidth).rounded(.down))

        return i >= 0 && i < heights.count ? i : nil
    }

    func clampedIndex(at x: Float) -> Int {
        min(max(Int(((x - origin.x) / columnWidth).rounded(.down)), 0), heights.count - 1)
    }

    func centerX(_ i: Int) -> Float {
        origin.x + (Float(i) + 0.5) * columnWidth
    }

    func floor(_ i: Int) -> Float {
        origin.y + bed[i]
    }

    func surface(_ i: Int) -> Float {
        origin.y + bed[i] + heights[i]
    }

    func fill(_ i: Int) -> Float {
        max(0, 1 - heights[i] / capacity[i])
    }

    func set(_ i: Int, _ height: Float) {
        heights[i] = max(0, height)
        invalidate(i, i)
    }

    func shapeCorners(radius: Float) {
        guard radius != cornerRadius else { return }

        cornerRadius = radius
        updateBed()
        invalidate(0, heights.count - 1)
    }

    func resize(columns: Int) {
        guard columns != heights.count else { return }

        heights = Array(heights.prefix(columns)) + Array(repeating: 0, count: max(0, columns - heights.count))
        visible = Array(repeating: true, count: columns)
        supported = Array(repeating: false, count: columns)
        supportedRange = nil
        updateCapacity()
        updateBed()
        invalidate(0, columns - 1)
    }

    func updateVisibility(clip: SIMD4<Float>) {
        let isInside = origin.y >= clip.y && origin.y <= clip.w

        isVisible = false

        for i in heights.indices {
            let x = centerX(i)

            visible[i] = isInside && x >= clip.x && x <= clip.z
            isVisible = isVisible || visible[i]
        }
    }

    func hide() {
        guard isVisible else { return }

        isVisible = false

        for i in visible.indices {
            visible[i] = false
        }
    }

    func refreshTop() {
        top = heights.max() ?? 0
    }

    @discardableResult
    func deposit(_ area: Float, at x: Float) -> Float {
        guard area > 0 else { return 0 }

        let center = Int(((x - origin.x) / columnWidth).rounded(.down)) - Self.kernel.count / 2
        let amount = area / columnWidth
        var missed: Float = 0

        for k in Self.kernel.indices {
            let i = center + k

            if i >= 0, i < heights.count {
                heights[i] += amount * Self.kernel[k]
            } else {
                missed += area * Self.kernel[k]
            }
        }

        invalidate(center, center + Self.kernel.count - 1)

        return missed
    }

    func hold(_ i: Int) {
        supported[i] = true

        if let range = supportedRange {
            supportedRange = min(range.lowerBound, i) ... max(range.upperBound, i)
        } else {
            supportedRange = i ... i
        }
    }

    func releaseSupport() {
        guard let range = supportedRange else { return }

        for i in range {
            supported[i] = false
        }

        supportedRange = nil
        invalidate(range.lowerBound, range.upperBound)
    }

    func relax(repose: Float, rounding: Float) {
        let count = heights.count

        guard count > 1, top > 0, dirtyLower <= dirtyUpper else { return }

        let lower = max(dirtyLower - Self.relaxReach, 0)
        let upper = min(dirtyUpper + Self.relaxReach, count - 1)
        let limit = repose * columnWidth
        let forwardFirst = parity
        let spillsLeft = opensAtEdges && lower == 0
        let spillsRight = opensAtEdges && upper == count - 1
        var spilledLeft: Float = 0
        var spilledRight: Float = 0
        var movedLower = Int.max
        var movedUpper = Int.min

        dirtyLower = 0
        dirtyUpper = -1

        parity.toggle()

        heights.withUnsafeMutableBufferPointer { h in
            bed.withUnsafeBufferPointer { b in
                supported.withUnsafeBufferPointer { held in
                    for pass in 0 ..< 6 {
                        let forward = (pass % 2 == 0) == forwardFirst

                        for k in lower ..< upper {
                            let i = forward ? k : upper - 1 - (k - lower)

                            if held[i] || held[i + 1] {
                                continue
                            }

                            let difference = (b[i] + h[i]) - (b[i + 1] + h[i + 1])

                            if difference > limit + 0.01 {
                                let transfer = min((difference - limit) * 0.5, h[i])
                                h[i] -= transfer
                                h[i + 1] += transfer

                                if transfer > 0 {
                                    movedLower = min(movedLower, i)
                                    movedUpper = max(movedUpper, i + 1)
                                }
                            } else if difference < -limit - 0.01 {
                                let transfer = min((-difference - limit) * 0.5, h[i + 1])
                                h[i + 1] -= transfer
                                h[i] += transfer

                                if transfer > 0 {
                                    movedLower = min(movedLower, i)
                                    movedUpper = max(movedUpper, i + 1)
                                }
                            }
                        }

                        if spillsLeft, !held[0], h[0] > limit + 0.01 {
                            let transfer = (h[0] - limit) * 0.5
                            h[0] -= transfer
                            spilledLeft += transfer
                            movedLower = 0
                            movedUpper = max(movedUpper, 0)
                        }

                        if spillsRight, !held[count - 1], h[count - 1] > limit + 0.01 {
                            let transfer = (h[count - 1] - limit) * 0.5
                            h[count - 1] -= transfer
                            spilledRight += transfer
                            movedLower = min(movedLower, count - 1)
                            movedUpper = count - 1
                        }
                    }

                    let kinkUpper = min(upper, count - 2)

                    guard max(1, lower) < kinkUpper else { return }

                    for i in max(1, lower) ..< kinkUpper where !(held[i - 1] || held[i] || held[i + 1] || held[i + 2]) {
                        let s0 = b[i - 1] + h[i - 1]
                        let s1 = b[i] + h[i]
                        let s2 = b[i + 1] + h[i + 1]
                        let s3 = b[i + 2] + h[i + 2]
                        let kink = (s1 - s2) - 0.5 * ((s0 - s1) + (s2 - s3))

                        guard abs(kink) > 0.02 else { continue }

                        let transfer = kink > 0 ? min(kink * rounding, h[i]) : max(kink * rounding, -h[i + 1])
                        h[i] -= transfer
                        h[i + 1] += transfer

                        if abs(transfer) > 0.003 {
                            movedLower = min(movedLower, i)
                            movedUpper = max(movedUpper, i + 1)
                        }
                    }
                }
            }
        }

        spill.left += spilledLeft * columnWidth
        spill.right += spilledRight * columnWidth

        if movedLower <= movedUpper {
            invalidate(movedLower, movedUpper)
        }
    }

    func thaw(dt: Float, down floor: Float, rate: Float, settle: Float) {
        guard top > 0 else { return }

        for i in heights.indices where heights[i] > 0 {
            let h = heights[i]

            heights[i] = h - min(h, (rate + max(0, h - floor) / settle) * dt)
        }
    }

    var isChanged: Bool {
        rendered != heights
    }

    func markRendered() {
        rendered = heights
    }

    func smoothed() -> [Float] {
        [Float](unsafeUninitializedCapacity: heights.count * 2) { buffer, initialized in
            if let base = buffer.baseAddress {
                writeSmoothed(into: base)
            }

            initialized = heights.count * 2
        }
    }

    func writeSmoothed(into buffer: UnsafeMutablePointer<Float>) {
        let count = heights.count

        for i in 0 ..< count {
            let left = heights[max(i - 1, 0)]
            let right = heights[min(i + 1, count - 1)]

            buffer[i] = bed[i] + 0.25 * left + 0.5 * heights[i] + 0.25 * right
            buffer[count + i] = bed[i]
        }
    }

    private func invalidate(_ lower: Int, _ upper: Int) {
        if dirtyLower > dirtyUpper {
            dirtyLower = lower
            dirtyUpper = upper
        } else {
            dirtyLower = min(dirtyLower, lower)
            dirtyUpper = max(dirtyUpper, upper)
        }
    }

    private func updateBed() {
        let radius = cornerRadius
        let span = width

        bed = (0 ..< heights.count).map { i in
            guard radius > 0 else { return 0 }

            let x = (Float(i) + 0.5) * columnWidth
            let inset = min(x, span - x)

            guard inset < radius else { return 0 }

            let u = 1 - inset / radius

            return -radius * (1 - max(0, 1 - u * u).squareRoot())
        }

        bedDepth = -(bed.min() ?? 0)
    }

    private func updateCapacity() {
        capacity = (0 ..< heights.count).map { i in
            let x = Float(i) * columnWidth
            let drift = 0.12 * sin(x * 0.0105 + phases.0) + 0.07 * sin(x * 0.037 + phases.1)

            return depth * (0.95 + drift)
        }
    }
}
