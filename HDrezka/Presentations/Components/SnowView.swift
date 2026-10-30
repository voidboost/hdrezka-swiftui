import Defaults
import MetalKit
import SwiftUI

private struct SnowUniforms {
    var viewSize: SIMD2<Float>
    var origin: SIMD2<Float> = .zero
    var columnWidth: Float
    var columnCount: Int32 = 0
    var time: Float
    var scale: Float
    var dark: Float
    var pileTop: Float = 0
    var pileBottom: Float = 0
    var surfaceWidth: Float = 0
    var cornerRadius: Float = 0
    var ledge: Float = 0
    var padding: Float = 0
}

final class SnowMetalView: MTKView {
    private static let framesInFlight = 3

    var snowSurfaces: SnowSurfaces?

    var configuration: SnowSimulation.Configuration {
        get { simulation.configuration }
        set { simulation.configuration = newValue }
    }

    private let simulation = SnowSimulation()
    private let semaphore = DispatchSemaphore(value: framesInFlight)
    private let epoch = CACurrentMediaTime()
    private var queue: MTLCommandQueue?
    private var spritePipeline: MTLRenderPipelineState?
    private var pilePipeline: MTLRenderPipelineState?
    private var spriteBuffers: [MTLBuffer] = []
    private var heightBuffers: [MTLBuffer] = []
    private var spriteCapacity = 0
    private var heightCapacity = 0
    private var slot = 0
    private var lastTime: CFTimeInterval = 0
    private var lastDark: Float = -1
    private var observations: [Task<Void, Never>] = []

    init() {
        super.init(frame: .zero, device: MTLCreateSystemDefaultDevice())
        setup()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        wantsLayer = true
        layer?.isOpaque = false
        colorPixelFormat = .bgra8Unorm
        clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        autoResizeDrawable = false
        preferredFramesPerSecond = 60

        if device == nil {
            device = MTLCreateSystemDefaultDevice()
        }

        guard let device, let library = device.makeDefaultLibrary() else { return }

        queue = device.makeCommandQueue()
        spritePipeline = makePipeline(device: device, library: library, vertex: "snowSpriteVertex", fragment: "snowSpriteFragment")
        pilePipeline = makePipeline(device: device, library: library, vertex: "snowPileVertex", fragment: "snowPileFragment")
    }

    private func makePipeline(device: MTLDevice, library: MTLLibrary, vertex: String, fragment: String) -> MTLRenderPipelineState? {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: vertex)
        descriptor.fragmentFunction = library.makeFunction(name: fragment)

        guard let attachment = descriptor.colorAttachments[0] else { return nil }

        attachment.pixelFormat = colorPixelFormat
        attachment.isBlendingEnabled = true
        attachment.sourceRGBBlendFactor = .one
        attachment.sourceAlphaBlendFactor = .one
        attachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
        attachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha

        return try? device.makeRenderPipelineState(descriptor: descriptor)
    }

    override func hitTest(_: NSPoint) -> NSView? {
        nil
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)

        drawableSize = newSize
        simulation.resize(width: Float(newSize.width), height: Float(newSize.height))
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        observations.forEach { $0.cancel() }
        observations.removeAll()

        guard let window else { return }

        let occlusionChanges = NotificationCenter.default.notifications(named: NSWindow.didChangeOcclusionStateNotification, object: window)

        updatePause()

        observations.append(Task { [weak self] in
            for await _ in occlusionChanges {
                self?.updatePause()
            }
        })
    }

    private func updatePause() {
        let isVisible = window?.occlusionState.contains(.visible) ?? false

        if isPaused, isVisible {
            lastTime = 0
        }

        isPaused = !isVisible
    }

    private var cursorLocation: SIMD2<Float>? {
        guard let window else { return nil }

        let point = convert(window.mouseLocationOutsideOfEventStream, from: nil)

        guard bounds.contains(point) else { return nil }

        return SIMD2(Float(point.x), Float(point.y))
    }

    override func draw(_: NSRect) {
        guard let queue, let spritePipeline, let pilePipeline, simulation.width > 0 else { return }

        let now = CACurrentMediaTime()
        let dt = lastTime > 0 ? Float(min(now - lastTime, 0.05)) : 1 / 60
        lastTime = now

        simulation.updateSurfaces(snowSurfaces, canvas: snowSurfaces?.canvas ?? .zero)
        simulation.step(dt: dt, cursor: cursorLocation)
        updateFrameRate()

        reserve(sprites: simulation.spriteCount, columns: simulation.columnCount)

        guard spriteBuffers.count == Self.framesInFlight, heightBuffers.count == Self.framesInFlight else { return }

        semaphore.wait()

        guard let pass = currentRenderPassDescriptor,
              let drawable = currentDrawable,
              let commandBuffer = queue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: pass)
        else {
            semaphore.signal()
            return
        }

        let index = slot % Self.framesInFlight
        slot += 1

        let spriteBuffer = spriteBuffers[index]
        let heightBuffer = heightBuffers[index]
        let heights = heightBuffer.contents().bindMemory(to: Float.self, capacity: heightCapacity)
        let sprites = simulation.writeSprites(into: spriteBuffer.contents().bindMemory(to: SnowSprite.self, capacity: spriteCapacity), capacity: spriteCapacity)
        let ground = simulation.writeGround(into: heights, capacity: heightCapacity)

        var uniforms = SnowUniforms(
            viewSize: SIMD2(simulation.width, simulation.height),
            columnWidth: SnowSimulation.columnWidth,
            time: Float((now - epoch).truncatingRemainder(dividingBy: 1000)),
            scale: Float(drawableSize.width / max(bounds.width, 1)),
            dark: effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? 1 : 0,
        )
        let uniformsLength = MemoryLayout<SnowUniforms>.stride

        if let ground {
            uniforms.origin = ground.origin
            uniforms.columnCount = Int32(ground.count)
            uniforms.pileTop = ground.top + 2
            uniforms.pileBottom = ground.bottom

            encoder.setRenderPipelineState(pilePipeline)
            encoder.setVertexBytes(&uniforms, length: uniformsLength, index: 0)
            encoder.setFragmentBuffer(heightBuffer, offset: 0, index: 0)
            encoder.setFragmentBytes(&uniforms, length: uniformsLength, index: 1)
            encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        }

        if sprites > 0 {
            encoder.setRenderPipelineState(spritePipeline)
            encoder.setVertexBuffer(spriteBuffer, offset: 0, index: 0)
            encoder.setVertexBytes(&uniforms, length: uniformsLength, index: 1)
            encoder.setFragmentBytes(&uniforms, length: uniformsLength, index: 0)
            encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: sprites)
        }

        encoder.endEncoding()
        drawLedges(into: commandBuffer, pipeline: pilePipeline, heights: heightBuffer, offset: (ground?.count ?? 0) * 2, uniforms: uniforms)
        commandBuffer.present(drawable)
        commandBuffer.addCompletedHandler(Self.completion(signaling: semaphore))
        commandBuffer.commit()
    }

    private func drawLedges(into commandBuffer: MTLCommandBuffer, pipeline: MTLRenderPipelineState, heights: MTLBuffer, offset: Int, uniforms: SnowUniforms) {
        guard let device, let ledges = snowSurfaces?.ledges.values else { return }

        let isAppearanceChanged = uniforms.dark != lastDark
        let headroom = SnowSimulation.headroom
        let values = heights.contents().bindMemory(to: Float.self, capacity: heightCapacity)
        var offset = offset

        lastDark = uniforms.dark
        for ledge in ledges {
            guard let view = ledge.view,
                  let layer = simulation.layer(for: ledge),
                  layer.isVisible,
                  view.needsRedraw || isAppearanceChanged || layer.isChanged,
                  view.bounds.width > 0,
                  offset + layer.count * 2 <= heightCapacity
            else { continue }

            if view.metalLayer.device == nil {
                view.metalLayer.device = device
            }

            guard let drawable = view.metalLayer.nextDrawable() else { continue }

            let pass = MTLRenderPassDescriptor()
            pass.colorAttachments[0].texture = drawable.texture
            pass.colorAttachments[0].loadAction = .clear
            pass.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
            pass.colorAttachments[0].storeAction = .store

            guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: pass) else { continue }

            if layer.top > 0.05 {
                let cornerRadius = Float(ledge.surface?.cornerRadius ?? 0)
                var uniforms = uniforms
                uniforms.viewSize = SIMD2(Float(view.bounds.width), Float(view.bounds.height))
                uniforms.origin = SIMD2(0, cornerRadius)
                uniforms.columnCount = Int32(layer.count)
                uniforms.scale = Float(view.metalLayer.contentsScale)
                uniforms.pileTop = headroom
                uniforms.pileBottom = -cornerRadius
                uniforms.surfaceWidth = Float(view.bounds.width)
                uniforms.cornerRadius = cornerRadius
                uniforms.ledge = 1

                layer.writeSmoothed(into: values + offset)

                encoder.setRenderPipelineState(pipeline)
                encoder.setVertexBytes(&uniforms, length: MemoryLayout<SnowUniforms>.stride, index: 0)
                encoder.setFragmentBuffer(heights, offset: offset * MemoryLayout<Float>.stride, index: 0)
                encoder.setFragmentBytes(&uniforms, length: MemoryLayout<SnowUniforms>.stride, index: 1)
                encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)

                offset += layer.count * 2
            }

            encoder.endEncoding()
            commandBuffer.present(drawable)
            view.needsRedraw = false
            layer.markRendered()
        }
    }

    private func updateFrameRate() {
        let fastest = window?.screen?.maximumFramesPerSecond ?? 60
        let frameRate = switch simulation.pace {
        case .calm:
            30
        case .lively:
            min(60, fastest)
        case .interactive:
            fastest
        }

        if preferredFramesPerSecond != frameRate {
            preferredFramesPerSecond = frameRate
        }
    }

    private nonisolated static func completion(signaling semaphore: DispatchSemaphore) -> MTLCommandBufferHandler {
        { _ in semaphore.signal() }
    }

    private func reserve(sprites: Int, columns: Int) {
        guard let device else { return }

        if sprites > spriteCapacity || spriteBuffers.isEmpty {
            spriteCapacity = max(1024, sprites * 3 / 2)
            spriteBuffers = makeBuffers(device: device, length: spriteCapacity * MemoryLayout<SnowSprite>.stride)
        }

        if columns > heightCapacity || heightBuffers.isEmpty {
            heightCapacity = max(1024, columns * 3 / 2)
            heightBuffers = makeBuffers(device: device, length: heightCapacity * MemoryLayout<Float>.stride)
        }
    }

    private func makeBuffers(device: MTLDevice, length: Int) -> [MTLBuffer] {
        (0 ..< Self.framesInFlight).compactMap { _ in
            device.makeBuffer(length: length, options: [.storageModeShared, .cpuCacheModeWriteCombined])
        }
    }
}

private struct SnowMetalViewRepresentable: NSViewRepresentable {
    let snowSurfaces: SnowSurfaces?
    let configuration: SnowSimulation.Configuration

    func makeNSView(context _: Context) -> SnowMetalView {
        let view = SnowMetalView()
        view.snowSurfaces = snowSurfaces
        view.configuration = configuration

        return view
    }

    func updateNSView(_ view: SnowMetalView, context _: Context) {
        view.snowSurfaces = snowSurfaces
        view.configuration = configuration
    }
}

struct SnowView: View {
    let snowSurfaces: SnowSurfaces?

    @Default(.snowIntensity) private var snowIntensity
    @Default(.snowAccumulates) private var snowAccumulates
    @Default(.snowMelts) private var snowMelts

    var body: some View {
        SnowMetalViewRepresentable(
            snowSurfaces: snowSurfaces,
            configuration: .init(intensity: snowIntensity, accumulates: snowAccumulates, melts: snowMelts),
        )
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { frame in
            snowSurfaces?.canvas = frame
        }
    }
}
