import Foundation
import simd

struct SnowSprite {
    var position: SIMD2<Float>
    var velocity: SIMD2<Float> = .zero
    var size: Float
    var alpha: Float
    var soft: Float
    var lump: Float = 0
}

struct SnowPile {
    var count: Int
    var origin: SIMD2<Float>
    var top: Float
    var bottom: Float
}

private struct Flake {
    var position: SIMD2<Float>
    var velocity: SIMD2<Float>
    var fallSpeed: Float
    var size: Float
    var depth: Float
    var alpha: Float
    var soft: Float
    var phase: Float
    var swayRate: Float
    var swayAmount: Float
    var settles: Bool
    var blown: Float = 0
}

private struct Grain {
    var position: SIMD2<Float>
    var velocity: SIMD2<Float>
    var area: Float
    var size: Float
    var lump: Float = 0
    var blown = false
}

private struct Mote {
    var position: SIMD2<Float>
    var velocity: SIMD2<Float>
    var size: Float
    var alpha: Float
    var age: Float = 0
    var life: Float
}

private struct RandomSource {
    private var state = UInt64.random(in: 1 ... UInt64.max)

    mutating func next() -> Float {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return Float(state >> 40) / Float(1 << 24)
    }

    mutating func range(_ lower: Float, _ upper: Float) -> Float {
        lower + (upper - lower) * next()
    }
}

@MainActor
final class SnowSimulation {
    struct Configuration: Equatable {
        var intensity: SnowIntensity = .steady
        var accumulates = true
        var melts = true
        var isEnabled = true
    }

    enum Pace {
        case calm
        case lively
        case interactive
    }

    nonisolated static let columnWidth: Float = 2
    nonisolated static let headroom: Float = 22

    private let groundDepth: Float = 40
    private let ledgeDepth: Float = 14
    private let thawDepth: Float = 8
    private let ledgeThawDepth: Float = 4
    private let thawRate: Float = 0.02
    private let thawTime: Float = 30
    private let thawBalance: Float = 184
    private let thawExponent: Float = 0.74
    private let deposition: Float = 1.1
    private let repose: Float = 0.8
    private let rounding: Float = 0.15
    private let cursorRadius: Float = 10
    private let cursorOffset = SIMD2<Float>(4, -8)
    private let gravity: Float = 2500
    private let grainDrag: Float = 0.8
    private let maxGrains = 12000
    private let maxMotes = 1500
    private let phaseWrap: Float = 20 * .pi
    private let gustSweep: Float = 0.6
    private let gustLength: Float = 2.2
    private let gustWind: Float = 1000
    private let gustLag: Float = 0.3
    private let bucketWidth: Float = 64

    var configuration = Configuration() {
        didSet {
            guard configuration != oldValue else { return }

            if configuration.isEnabled != oldValue.isEnabled {
                gust = configuration.isEnabled ? nil : (clock, breeze() < 0 ? -1 : 1)
            }

            if configuration.intensity == .variable, oldValue.intensity != .variable {
                nextShift = clock
            }

            if configuration.intensity != .variable {
                strength = 1
                strengthTarget = 1
            }

            updateTarget()
        }
    }

    private let columnWidth = SnowSimulation.columnWidth

    private(set) var width: Float = 0
    private(set) var height: Float = 0
    private(set) var pace = Pace.calm

    private let ground: SnowLayer
    private var ledges: [ObjectIdentifier: SnowLayer] = [:]
    private var ledgeList: [SnowLayer] = []
    private var buckets: [[SnowLayer]] = []
    private var removedLedges: [ObjectIdentifier] = []
    private var layers: [SnowLayer]
    private var heldLayers: [SnowLayer] = []
    private var touchedLayers: [SnowLayer] = []
    private var flakes: [Flake] = []
    private var grains: [Grain] = []
    private var motes: [Mote] = []
    private var targetFlakes = 0
    private var random = RandomSource()
    private var clock: Double = 0
    private var cursor: SIMD2<Float>?
    private var cursorVelocity = SIMD2<Float>(repeating: 0)
    private var lastCursorPush: Double = -10
    private var strength: Float = 1
    private var strengthTarget: Float = 1
    private var nextShift: Double = 0
    private var gust: (start: Double, direction: Float)?

    init() {
        var seed = RandomSource()

        ground = SnowLayer(
            origin: .zero,
            columns: 1,
            depth: groundDepth,
            opensAtEdges: false,
            phases: (seed.range(0, 2 * .pi), seed.range(0, 2 * .pi)),
        )
        layers = [ground]
    }

    var isIdle: Bool {
        !configuration.isEnabled && gust == nil && flakes.isEmpty && grains.isEmpty && motes.isEmpty && layers.allSatisfy { $0.top <= 0.05 }
    }

    var spriteCount: Int {
        flakes.count + grains.count + motes.count
    }

    var columnCount: Int {
        layers.reduce(0) { $0 + $1.count * 2 }
    }

    private var flakesPerMegapoint: Float {
        switch configuration.intensity {
        case .light:
            150
        case .steady, .variable:
            380
        case .heavy:
            800
        }
    }

    func resize(width: Float, height: Float) {
        guard width > 0, height > 0, width != self.width || height != self.height else { return }

        ground.resize(columns: Int((width / columnWidth).rounded(.up)) + 1)
        self.width = width
        self.height = height
        updateTarget()
    }

    func updateSurfaces(_ surfaces: SnowSurfaces?, canvas: CGRect) {
        let ledges = surfaces?.ledges ?? [:]
        var isChanged = false

        for (id, layer) in self.ledges {
            guard let ledge = ledges[id], let surface = ledge.surface, let geometry = geometry(of: surface, in: canvas) else {
                removedLedges.append(id)
                continue
            }

            guard surfaces?.isShown(ledge) ?? true else {
                layer.hide()
                continue
            }

            layer.resize(columns: geometry.columns)
            layer.origin = geometry.origin
            layer.shapeCorners(radius: Float(surface.cornerRadius), exponent: Float(surface.cornerExponent))
            layer.updateVisibility(clip: geometry.clip)
        }

        for id in removedLedges {
            if let layer = self.ledges.removeValue(forKey: id) {
                shed(layer, share: 1, velocity: .zero)
            }

            isChanged = true
        }

        removedLedges.removeAll(keepingCapacity: true)

        for (id, ledge) in ledges where self.ledges[id] == nil {
            guard let surface = ledge.surface, surfaces?.isShown(ledge) ?? true, let geometry = geometry(of: surface, in: canvas) else { continue }

            let layer = SnowLayer(
                origin: geometry.origin,
                columns: geometry.columns,
                depth: ledgeDepth,
                opensAtEdges: true,
                phases: (random.range(0, 2 * .pi), random.range(0, 2 * .pi)),
            )

            layer.shapeCorners(radius: Float(surface.cornerRadius), exponent: Float(surface.cornerExponent))
            layer.updateVisibility(clip: geometry.clip)
            self.ledges[id] = layer
            isChanged = true
        }

        if isChanged {
            ledgeList = Array(self.ledges.values)
            layers = [ground] + ledgeList
        }
    }

    func layer(for ledge: SnowLedge) -> SnowLayer? {
        ledges[ObjectIdentifier(ledge)]
    }

    func step(dt: Float, cursor point: SIMD2<Float>?) {
        guard width > 0 else { return }

        clock += Double(dt)

        updateBuckets()
        vary(dt: dt)
        trackCursor(point, dt: dt)
        blow(dt: dt)
        advanceFlakes(dt: dt)
        advanceGrains(dt: dt)
        advanceMotes(dt: dt)
        settle(dt: dt)
        spawnFlakes()

        for layer in layers {
            layer.refreshTop()
            layer.previousBaseY = layer.origin.y
        }

        if clock - lastCursorPush < 0.3 {
            pace = .interactive
        } else if grains.count > 24 {
            pace = .lively
        } else {
            pace = .calm
        }
    }

    func writeSprites(into buffer: UnsafeMutablePointer<SnowSprite>, capacity: Int) -> Int {
        var count = 0

        for flake in flakes where count < capacity {
            buffer[count] = SnowSprite(position: flake.position, velocity: flake.velocity, size: flake.size, alpha: flake.alpha, soft: flake.soft)
            count += 1
        }

        for grain in grains where count < capacity {
            buffer[count] = SnowSprite(
                position: grain.position,
                velocity: grain.velocity,
                size: grain.size,
                alpha: grain.lump > 0 ? 0.97 : grain.blown ? 0.8 : 0.95,
                soft: grain.lump > 0 ? 0.2 : 0.3,
                lump: grain.lump,
            )
            count += 1
        }

        for mote in motes where count < capacity {
            let t = mote.age / mote.life
            let fade = min(1, mote.age / 0.06) * pow(1 - t, 1.5)

            buffer[count] = SnowSprite(position: mote.position, size: mote.size * (1 + t), alpha: mote.alpha * fade, soft: 1)
            count += 1
        }

        return count
    }

    func writeGround(into buffer: UnsafeMutablePointer<Float>, capacity: Int) -> SnowPile? {
        guard ground.top > 0.05, ground.count * 2 <= capacity else { return nil }

        ground.writeSmoothed(into: buffer)

        return SnowPile(count: ground.count, origin: ground.origin, top: ground.top, bottom: -ground.bedDepth)
    }

    private func geometry(of surface: SnowSurface, in canvas: CGRect) -> (origin: SIMD2<Float>, columns: Int, clip: SIMD4<Float>)? {
        let frame = local(surface.frame, in: canvas)
        let columns = Int((frame.z - frame.x) / columnWidth)

        guard columns >= 8 else { return nil }

        let clip = local(surface.clip, in: canvas)

        return (SIMD2(frame.x, frame.w), columns, SIMD4(max(clip.x, 0), max(clip.y, 0), min(clip.z, width), min(clip.w, height)))
    }

    private func local(_ rect: CGRect, in canvas: CGRect) -> SIMD4<Float> {
        SIMD4(
            Float(rect.minX - canvas.minX),
            Float(canvas.maxY - rect.maxY),
            Float(rect.maxX - canvas.minX),
            Float(canvas.maxY - rect.minY),
        )
    }

    private func shed(_ ledge: SnowLayer, share: Float, velocity: SIMD2<Float>) {
        var start = 0

        while start < ledge.count {
            let end = min(ledge.count, start + Int(random.range(2, 7)))
            var area: Float = 0
            var lowest = Float.greatestFiniteMagnitude
            var highest = -Float.greatestFiniteMagnitude

            for i in start ..< end where ledge.heights[i] > 0.05 && ledge.visible[i] {
                let h = ledge.heights[i]

                area += h * share * columnWidth
                lowest = min(lowest, ledge.floor(i) + h * (1 - share))
                highest = max(highest, ledge.floor(i) + h)
            }

            let cohesion = area > 14 ? random.range(0.4, 0.7) : 0

            for i in start ..< end where ledge.heights[i] > 0.05 {
                let h = ledge.heights[i]
                let amount = h * share

                ledge.set(i, h - amount)

                guard ledge.visible[i] else { continue }

                release(
                    amount * columnWidth * (1 - cohesion),
                    at: SIMD2(ledge.centerX(i), ledge.floor(i) + h - amount),
                    velocity: velocity,
                    spread: SIMD2(columnWidth / 2, amount),
                    scatter: 0.25,
                )
            }

            if cohesion > 0 {
                let left = ledge.centerX(start)
                let right = ledge.centerX(end - 1)

                throwLump(area * cohesion, at: SIMD2((left + right) / 2, (lowest + highest) / 2), velocity: velocity)
            }

            start = end
        }
    }

    private func throwLump(_ area: Float, at position: SIMD2<Float>, velocity: SIMD2<Float>) {
        let pieces = Int(area / 90) + 1

        for _ in 0 ..< pieces where grains.count < maxGrains {
            let share = area / Float(pieces)

            grains.append(
                Grain(
                    position: position + SIMD2(random.range(-2, 2), random.range(-1, 1)),
                    velocity: velocity * (1 + random.range(-0.2, 0.2)) + SIMD2(random.range(-25, 25), random.range(-80, 0)),
                    area: share,
                    size: min(11, share.squareRoot() * 1.05),
                    lump: random.range(0.05, 1),
                ),
            )
        }
    }

    private func burst(_ lump: Grain, into layer: SnowLayer) {
        let impact = max(0, -lump.velocity.y)
        let force = min(max(impact / 900, 0.35), 1.3)
        let crumbs = lump.area * 0.18

        for spot: Float in [-0.3, 0, 0.3] {
            let x = lump.position.x + spot * lump.size
            let missed = layer.deposit((lump.area - crumbs) / 3, at: x)

            dropPast(layer, missed, near: x, velocity: lump.velocity.x * 0.3)
        }

        let surface = layer.index(at: lump.position.x).map { layer.surface($0) } ?? lump.position.y

        release(
            crumbs,
            at: SIMD2(lump.position.x, surface + 1),
            velocity: SIMD2(lump.velocity.x * 0.3, impact * random.range(0.08, 0.16)),
            spread: SIMD2(lump.size * 0.4, 1),
            scatter: 0.6,
        )

        let count = min(maxMotes - motes.count, Int(2 + lump.size * 0.6 * force))

        guard count > 0 else { return }

        for _ in 0 ..< count {
            let angle = random.range(0.15, .pi - 0.15)
            let speed = random.range(25, 110) * force

            motes.append(
                Mote(
                    position: SIMD2(lump.position.x + random.range(-0.5, 0.5) * lump.size, surface + random.range(0, lump.size * 0.4)),
                    velocity: SIMD2(cos(angle) * speed * 1.4 + lump.velocity.x * 0.2, sin(angle) * speed * 0.6),
                    size: random.range(0.3, 0.6) * lump.size + 1,
                    alpha: random.range(0.1, 0.22),
                    life: random.range(0.45, 0.9),
                ),
            )
        }
    }

    private func release(_ area: Float, at position: SIMD2<Float>, velocity: SIMD2<Float>, spread: SIMD2<Float> = SIMD2(1, 1), scatter: Float = 0) {
        guard area > 0.02 else { return }

        let room = maxGrains - grains.count

        guard room > 0 else {
            ground.deposit(area, at: position.x)
            return
        }

        let count = min(room, max(1, min(6, Int(area / 3))))
        let share = area / Float(count)

        for _ in 0 ..< count {
            grains.append(
                Grain(
                    position: position + SIMD2(random.range(-spread.x, spread.x), random.range(0, spread.y)),
                    velocity: velocity * (1 + random.range(-scatter, scatter)) + SIMD2(random.range(-12, 12) - 40 * scatter * random.range(-1, 1), random.range(-10, 8)),
                    area: share,
                    size: min(5, max(1.1, share.squareRoot() * 1.05)),
                ),
            )
        }
    }

    private func dropPast(_ layer: SnowLayer, _ area: Float, near x: Float, velocity: Float) {
        guard layer.opensAtEdges, area > 0.05 else { return }

        let leftSide = x < layer.origin.x + layer.width / 2

        release(area, at: edgePoint(of: layer, left: leftSide), velocity: SIMD2(velocity, -10), spread: SIMD2(0.25, 1))
    }

    private func edgePoint(of layer: SnowLayer, left: Bool) -> SIMD2<Float> {
        let end = left ? 0 : layer.count - 1
        let x = left ? layer.origin.x - 0.75 : layer.origin.x + layer.width + 0.75

        return SIMD2(x, layer.surface(end))
    }

    private func trackCursor(_ point: SIMD2<Float>?, dt: Float) {
        for layer in heldLayers {
            layer.releaseSupport()
        }

        heldLayers.removeAll(keepingCapacity: true)

        guard let point else {
            cursor = nil
            cursorVelocity = .zero
            return
        }

        let center = point + cursorOffset

        guard let previous = cursor else {
            cursor = center
            return
        }

        cursor = center

        let delta = center - previous
        var velocity = delta / max(dt, 1.0 / 240)
        let speed = simd_length(velocity)

        if speed > 3000 {
            velocity *= 3000 / speed
        }

        cursorVelocity += (velocity - cursorVelocity) * 0.5

        let low = min(center.y, previous.y) - cursorRadius
        let high = max(center.y, previous.y) + cursorRadius
        let left = min(center.x, previous.x) - cursorRadius
        let right = max(center.x, previous.x) + cursorRadius
        touchedLayers.removeAll(keepingCapacity: true)

        for layer in layers where layer.isVisible
            && low <= layer.origin.y + layer.top + 1
            && high >= layer.origin.y - layer.bedDepth
            && right >= layer.origin.x
            && left <= layer.origin.x + layer.width
            && (layer === ground || layer.top > 0.01)
        {
            touchedLayers.append(layer)
        }

        guard !touchedLayers.isEmpty else { return }

        let distance = simd_length(delta)

        if distance > 400 {
            for layer in touchedLayers {
                carve(layer, at: center, velocity: .zero, travel: 0, final: true)
            }

            return
        }

        let steps = Int(distance / (cursorRadius * 0.5)) + 1

        for step in 1 ... steps {
            let position = previous + delta * (Float(step) / Float(steps))

            for layer in touchedLayers {
                carve(layer, at: position, velocity: velocity, travel: distance / Float(steps), final: step == steps)
            }
        }
    }

    private func carve(_ layer: SnowLayer, at center: SIMD2<Float>, velocity: SIMD2<Float>, travel: Float, final: Bool) {
        let radius = cursorRadius
        let lower = max(0, Int(((center.x - radius - layer.origin.x) / columnWidth).rounded(.down)))
        let upper = min(layer.count - 1, Int(((center.x + radius - layer.origin.x) / columnWidth).rounded(.down)))

        guard lower <= upper else { return }

        let local = center.y - layer.origin.y
        let sprayShare = smoothstep(60, 420, simd_length(velocity))
        var pushedLeft: Float = 0
        var pushedRight: Float = 0

        for i in lower ... upper where layer.visible[i] {
            let x = layer.centerX(i)
            let dx = x - center.x
            let reach = radius * radius - dx * dx

            guard reach > 0 else { continue }

            let half = reach.squareRoot()
            let bedLevel = layer.bed[i]
            let bottom = max(0, local - half - bedLevel)
            let top = local + half - bedLevel

            guard top > bottom else { continue }

            let h = layer.heights[i]
            let buried = h > top

            if final, !buried, h >= bottom - 1 {
                if !heldLayers.contains(where: { $0 === layer }) {
                    heldLayers.append(layer)
                }

                layer.hold(i)
            }

            guard h > bottom + 0.01 else { continue }

            let removed = buried ? (top - bottom) * min(1, travel / (2 * radius)) : h - bottom

            guard removed > 0.001 else { continue }

            layer.set(i, h - removed)
            lastCursorPush = clock

            let area = removed * columnWidth
            let surface = layer.floor(i) + (buried ? h - removed : h)
            let sprayed = sprayShare > 0 ? emit(area * sprayShare, from: SIMD2(x, surface), center: center, velocity: velocity) : 0
            let side = abs(velocity.x) > 40 ? velocity.x : dx

            if side < 0 {
                pushedLeft += area - sprayed
            } else {
                pushedRight += area - sprayed
            }
        }

        for (area, x) in [(pushedLeft, center.x - radius - columnWidth * 3), (pushedRight, center.x + radius + columnWidth * 3)] where area > 0 {
            let missed = layer.deposit(area, at: x)

            dropPast(layer, missed, near: x, velocity: velocity.x * 0.5)
        }
    }

    private func emit(_ area: Float, from origin: SIMD2<Float>, center: SIMD2<Float>, velocity: SIMD2<Float>) -> Float {
        guard area > 0.6, grains.count < maxGrains else { return 0 }

        let count = min(4, Int(area / 1.6) + 1)
        let share = area / Float(count)
        let speed = simd_length(velocity)
        let offset = origin - center
        let length = simd_length(offset)
        let outward = length > 0.001 ? offset / length : SIMD2<Float>(0, 1)

        for _ in 0 ..< count {
            var v = velocity * random.range(0.55, 1.25) + outward * (speed * random.range(0.05, 0.25))
            v.y += speed * random.range(0.02, 0.2)
            v += SIMD2(random.range(-30, 30), random.range(-20, 40))

            grains.append(
                Grain(
                    position: origin + SIMD2(random.range(-1, 1), random.range(0, 2)),
                    velocity: v,
                    area: share,
                    size: min(4.2, max(1.1, share.squareRoot() * 1.05)),
                ),
            )
        }

        return area
    }

    private func updateBuckets() {
        let count = Int(width / bucketWidth) + 1

        if buckets.count != count {
            buckets = Array(repeating: [], count: count)
        } else {
            for i in buckets.indices {
                buckets[i].removeAll(keepingCapacity: true)
            }
        }

        for ledge in ledgeList where ledge.isVisible {
            let lower = max(0, Int((ledge.origin.x / bucketWidth).rounded(.down)))
            let upper = min(count - 1, Int(((ledge.origin.x + ledge.width) / bucketWidth).rounded(.down)))

            guard lower <= upper else { continue }

            for i in lower ... upper {
                buckets[i].append(ledge)
            }
        }
    }

    private func landing(x: Float, from: Float, to: Float) -> (layer: SnowLayer, index: Int)? {
        var hit: (layer: SnowLayer, index: Int)?
        var highest = -Float.greatestFiniteMagnitude
        let bucket = Int((x / bucketWidth).rounded(.down))

        if bucket >= 0, bucket < buckets.count {
            for ledge in buckets[bucket] {
                guard let i = ledge.index(at: x), ledge.visible[i] else { continue }

                let surface = ledge.surface(i)

                if from >= ledge.previousBaseY + ledge.bed[i], to <= surface, surface > highest {
                    hit = (ledge, i)
                    highest = surface
                }
            }
        }

        if let hit {
            return hit
        }

        let i = ground.clampedIndex(at: x)

        return to <= ground.surface(i) ? (ground, i) : nil
    }

    private func advanceFlakes(dt: Float) {
        let wind = breeze()
        let follow = min(1, dt * 1.2)
        let settle = min(1, dt * 1.6)
        let wakeRadius: Float = 80
        var wakeVelocity = cursorVelocity
        let wakeSpeed = simd_length(wakeVelocity)

        if wakeSpeed > 500 {
            wakeVelocity *= 500 / wakeSpeed
        }

        let wakeCenter = cursor ?? SIMD2(-10000, -10000)
        let wakeActive = wakeSpeed > 20
        let accumulates = configuration.accumulates
        var i = flakes.count - 1

        while i >= 0 {
            var flake = flakes[i]

            if flake.blown != 0 {
                flake.velocity.x += (flake.blown * gustWind * (1.3 + 1.3 * flake.depth) - flake.velocity.x) * min(1, dt * 2.5)
            } else {
                flake.velocity.x += (wind * (0.35 + 0.65 * flake.depth) - flake.velocity.x) * follow
            }

            flake.velocity.y += (-flake.fallSpeed - flake.velocity.y) * settle

            if wakeActive {
                let distanceSquared = simd_length_squared(flake.position - wakeCenter)

                if distanceSquared < wakeRadius * wakeRadius {
                    let falloff = 1 - distanceSquared.squareRoot() / wakeRadius

                    flake.velocity += (wakeVelocity - flake.velocity) * min(1, falloff * falloff * 4 * dt)
                }
            }

            flake.phase += flake.swayRate * dt

            if flake.phase > phaseWrap {
                flake.phase -= phaseWrap
            }

            let sway = (cos(flake.phase) + 0.3 * cos(flake.phase * 2.3)) * flake.swayAmount
            let flutter = 1 + 0.12 * sin(flake.phase * 1.3)
            let previousY = flake.position.y

            flake.position.x += (flake.velocity.x + sway) * dt
            flake.position.y += flake.velocity.y * flutter * dt

            if flake.blown != 0, flake.position.x < -30 || flake.position.x > width + 30 {
                recycle(i)
                i -= 1
                continue
            }

            if flake.position.x < -30 {
                flake.position.x += width + 60
            } else if flake.position.x > width + 30 {
                flake.position.x -= width + 60
            }

            if flake.settles, accumulates, flake.blown == 0 {
                if let hit = landing(x: flake.position.x, from: previousY, to: flake.position.y) {
                    hit.layer.deposit(flake.size * flake.size * deposition * hit.layer.fill(hit.index), at: flake.position.x)
                    recycle(i)
                    i -= 1
                    continue
                }
            } else if flake.position.y < -flake.size * 2 {
                recycle(i)
                i -= 1
                continue
            }

            flakes[i] = flake
            i -= 1
        }
    }

    private func advanceGrains(dt: Float) {
        guard !grains.isEmpty else { return }

        let damping = exp(-grainDrag * dt)
        var i = grains.count - 1

        while i >= 0 {
            var grain = grains[i]
            let previousY = grain.position.y

            if grain.blown {
                grain.velocity.x += ((grain.velocity.x < 0 ? -gustWind : gustWind) * 1.6 - grain.velocity.x) * min(1, dt * 2)
                grain.velocity.y -= gravity * 0.08 * dt
            } else {
                grain.velocity.y -= gravity * dt
                grain.velocity *= damping
            }

            grain.position += grain.velocity * dt

            if grain.position.x < -10 || grain.position.x > width + 10 || grain.position.y < -10 {
                removeGrain(i)
            } else if !grain.blown, grain.velocity.y <= 0, let hit = landing(x: grain.position.x, from: previousY, to: grain.position.y) {
                if grain.lump > 0 {
                    burst(grain, into: hit.layer)
                } else {
                    let missed = hit.layer.deposit(grain.area, at: grain.position.x)

                    dropPast(hit.layer, missed, near: grain.position.x, velocity: grain.velocity.x * 0.5)
                }

                removeGrain(i)
            } else {
                grains[i] = grain
            }

            i -= 1
        }
    }

    private func advanceMotes(dt: Float) {
        guard !motes.isEmpty else { return }

        let damping = exp(-3.2 * dt)
        let drift = (breeze() + gustSpeed()) * 0.4
        var i = motes.count - 1

        while i >= 0 {
            var mote = motes[i]
            mote.age += dt

            if mote.age >= mote.life {
                motes.swapAt(i, motes.count - 1)
                motes.removeLast()
            } else {
                mote.velocity.y -= 35 * dt
                mote.velocity *= damping
                mote.position += (mote.velocity + SIMD2(drift, 0)) * dt
                motes[i] = mote
            }

            i -= 1
        }
    }

    private func removeGrain(_ i: Int) {
        grains.swapAt(i, grains.count - 1)
        grains.removeLast()
    }

    private func recycle(_ i: Int) {
        if flakes.count <= targetFlakes {
            flakes[i] = makeFlake(y: height + random.range(4, 40))
        } else {
            removeFlake(i)
        }
    }

    private func removeFlake(_ i: Int) {
        flakes.swapAt(i, flakes.count - 1)
        flakes.removeLast()
    }

    private func spawnFlakes() {
        guard flakes.count < targetFlakes else { return }

        for _ in flakes.count ..< targetFlakes {
            flakes.append(makeFlake(y: height + random.range(0, height * 0.8)))
        }
    }

    private func makeFlake(y: Float) -> Flake {
        let near = random.next() < 0.02
        let depth = near ? 1 : pow(random.next(), 1.6)
        let fallSpeed = near ? random.range(75, 100) : 16 + depth * 50 + random.range(0, 10)

        return Flake(
            position: SIMD2(random.range(-30, width + 30), y),
            velocity: SIMD2((breeze() + gustSpeed()) * (0.35 + 0.65 * depth), -fallSpeed),
            fallSpeed: fallSpeed,
            size: near ? random.range(8, 13) : 1.4 + depth * 4.4 + random.range(0, 1),
            depth: depth,
            alpha: near ? 0.28 : 0.4 + depth * 0.5,
            soft: near ? 0.95 : 0.75 - depth * 0.45,
            phase: random.range(0, phaseWrap),
            swayRate: random.range(0.5, 1.4),
            swayAmount: near ? random.range(10, 20) : random.range(4, 9) + depth * 10,
            settles: !near,
        )
    }

    private func blow(dt: Float) {
        guard let gust else { return }

        let age = Float(clock - gust.start)

        if age >= gustLength, !flakes.contains(where: { $0.blown != 0 }) {
            self.gust = nil
            return
        }

        let direction = gust.direction
        let front = gustFront(age: age, direction: direction)
        let trailing = gustFront(age: age - gustLag, direction: direction)
        let isFinishing = age > gustSweep + 0.8

        for i in flakes.indices where flakes[i].blown == 0 {
            if isFinishing || (trailing - flakes[i].position.x) * direction > flakes[i].phase / phaseWrap * 240 {
                flakes[i].blown = direction
            }
        }

        for layer in layers {
            var dust: Float = 0

            for i in 0 ..< layer.count where layer.heights[i] > 0 {
                let x = layer.centerX(i)

                guard isFinishing || (front - x) * direction > 0 else { continue }

                let h = layer.heights[i]
                let surface = layer.surface(i)
                let loss = isFinishing ? h : min(h, (h * 8 + 50) * dt)

                layer.set(i, h - loss)

                guard layer.visible[i] else { continue }

                dust += loss * columnWidth

                while dust >= 3.5 {
                    lift(at: SIMD2(x, surface), direction: direction)
                    dust -= 3.5
                }
            }
        }
    }

    private func gustFront(age: Float, direction: Float) -> Float {
        let margin: Float = 40
        let t = min(max(age / gustSweep, 0), 1)
        let travel = (width + 2 * margin) * (1 - (1 - t) * (1 - t))

        return direction > 0 ? -margin + travel : width + margin - travel
    }

    private func gustSpeed() -> Float {
        guard let gust else { return 0 }

        let age = Float(clock - gust.start)

        return gust.direction * gustWind * smoothstep(0, 0.12, age) * (1 - smoothstep(0.9, gustLength, age))
    }

    private func lift(at position: SIMD2<Float>, direction: Float) {
        guard grains.count < maxGrains else { return }

        grains.append(
            Grain(
                position: position + SIMD2(random.range(-1, 1), -random.range(0, 3)),
                velocity: SIMD2(direction * random.range(800, 1800), random.range(60, 420)),
                area: 0,
                size: random.range(1.1, 2.6),
                blown: true,
            ),
        )

        guard random.next() < 0.35, motes.count < maxMotes else { return }

        motes.append(
            Mote(
                position: position,
                velocity: SIMD2(direction * random.range(200, 600), random.range(20, 120)),
                size: random.range(6, 14),
                alpha: random.range(0.06, 0.14),
                life: random.range(0.6, 1.3),
            ),
        )
    }

    private func breeze() -> Float {
        let t = clock
        let breeze = Float(10 * sin(t * 0.07) + 6 * sin(t * 0.19 + 1.7) + 3 * sin(t * 0.43 + 4.1))

        return breeze * (0.6 + 0.4 * strength)
    }

    private func vary(dt: Float) {
        if configuration.intensity != .variable {
            strengthTarget = 1
        } else if clock >= nextShift {
            let roll = random.next()

            strengthTarget = roll < 0.25 ? random.range(0.25, 0.5) : roll < 0.75 ? random.range(0.7, 1.3) : random.range(1.5, 2.1)
            nextShift = clock + Double(random.range(60, 240))
        }

        guard abs(strengthTarget - strength) > 0.001 else { return }

        strength += (strengthTarget - strength) * (1 - exp(-dt / 25))
        updateTarget()
    }

    private func settle(dt: Float) {
        let falling = flakesPerMegapoint * strength
        let meltPace = falling > 0 ? pow(falling / thawBalance, thawExponent) : 1

        for layer in layers {
            if !configuration.accumulates || configuration.melts {
                let floor = !configuration.accumulates ? 0 : (layer === ground ? thawDepth : ledgeThawDepth)

                layer.thaw(dt: dt * meltPace, down: floor, rate: thawRate, settle: thawTime)
            }

            layer.relax(repose: repose, rounding: rounding)

            guard layer.isVisible else {
                layer.spill = (0, 0)
                continue
            }

            if layer.spill.left > 1.5 {
                release(layer.spill.left, at: edgePoint(of: layer, left: true), velocity: SIMD2(-6, -15), spread: SIMD2(0.25, 1))
                layer.spill.left = 0
            }

            if layer.spill.right > 1.5 {
                release(layer.spill.right, at: edgePoint(of: layer, left: false), velocity: SIMD2(6, -15), spread: SIMD2(0.25, 1))
                layer.spill.right = 0
            }
        }
    }

    private func updateTarget() {
        targetFlakes = configuration.isEnabled ? Int(flakesPerMegapoint * strength * width * height / 1_000_000) : 0
    }
}

private func smoothstep(_ edge0: Float, _ edge1: Float, _ x: Float) -> Float {
    let t = min(max((x - edge0) / (edge1 - edge0), 0), 1)

    return t * t * (3 - 2 * t)
}
