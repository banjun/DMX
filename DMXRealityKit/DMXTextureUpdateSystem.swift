import RealityKit
import Metal
import Combine
import DMX
import RealityKitContent

struct DMXTextureUpdateSystem: System {
    /// should be completed before loading scene
    static func registerSystemAndComponents() {
        DMXReceiverComponent.registerComponent()
        LightMovingHeadComponent.registerComponent()
        DMXTextureUpdateSystem.registerSystem()
    }

    static let query = EntityQuery(where: .has(DMXHolderComponent.self))

    // currently supporting only 1 universe. make height > 1 to support more universe (along with updating shadergraph)
    private let llTexture: LowLevelTexture = try! .init(descriptor: .init(pixelFormat: .rgba8Unorm, width: DMX.RawValue.count / 4, height: 1, textureUsage: [.shaderRead]))
    private let metalTexture: MTLTexture
    private let textureResource: TextureResource
    private let textureBuffer: MTLBuffer
    private let commandQueue: MTLCommandQueue

    private var cancellables: Set<AnyCancellable> = []

    init(scene: RealityKit.Scene) {
        metalTexture = llTexture.read()
        let textureResource = try! TextureResource(from: llTexture)
        self.textureResource = textureResource
        let device = MTLCreateSystemDefaultDevice()!
        textureBuffer = device.makeBuffer(length: DMX.RawValue.count)!
        commandQueue = device.makeCommandQueue()!

        // MARK: Setup ShaderGraphMaterial input values from its Component value

        scene.subscribe(to: ComponentEvents.DidAdd.self, componentType: DMXReceiverComponent.self) { event in
            let entity = event.entity
            guard let c = entity.components[DMXReceiverComponent.self] else { return }

            entity.forEachModelEntity { e in
                e.mapShaderGraphMaterials { m in
                    let params: [String: MaterialParameters.Value] = [
                        "DMX": .textureResource(textureResource),
                        "start": .int(c.start),
                    ]
                    params.forEach { k, v in
                        let k = "Component_\(k)"
                        if m.parameterNames.contains(k) {
                            NSLog("%@", "setting \(k) = \(v), to \(e.name)")
                            try! m.setParameter(name: k, value: v)
                        }
                    }
                }
            }
        }.store(in: &cancellables)

        scene.subscribe(to: ComponentEvents.DidAdd.self, componentType: LightMovingHeadComponent.self) { event in
            let entity = event.entity
            guard let c = entity.components[LightMovingHeadComponent.self] else { return }

            entity.forEachModelEntity { e in
                e.mapShaderGraphMaterials { m in
                    let params: [String: MaterialParameters.Value] = [
                        "pivot": .simd3Float(c.pivot),
                        "panMin": .float(c.panMin),
                        "panMax": .float(c.panMax),
                        "tiltMin": .float(c.tiltMin),
                        "tiltMax": .float(c.tiltMax),
                    ]
                    params.forEach { k, v in
                        let k = "Component_\(k)"
                        if m.parameterNames.contains(k) {
                            NSLog("%@", "setting \(k) = \(v), to \(e.name)")
                            try! m.setParameter(name: k, value: v)
                        }
                    }
                }
            }
        }.store(in: &cancellables)
    }

    func update(context: SceneUpdateContext) {
        for e in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            var dmx = e.components[DMXHolderComponent.self]!.dmxHolder.dmx

            guard let commandBuffer = commandQueue.makeCommandBuffer(),
                  let blit = commandBuffer.makeBlitCommandEncoder() else { return }

            // copy DMX into MTLBuffer
            withUnsafeBytes(of: &dmx) {
                textureBuffer.contents().copyMemory(from: $0.baseAddress!, byteCount: DMX.RawValue.count)
            }
            // copy MTLBuffer into LowLevelTexture
            let metalTexture = metalTexture // or using llTexture.replace(using: commandBuffer) is more reliable in theory but heavier
            blit.copy(from: textureBuffer, sourceOffset: 0, sourceBytesPerRow: DMX.RawValue.count, sourceBytesPerImage: DMX.RawValue.count, sourceSize: .init(width: DMX.RawValue.count / 4, height: 1, depth: 1), to: metalTexture, destinationSlice: 0, destinationLevel: 0, destinationOrigin: .init())
            blit.endEncoding()
            commandBuffer.commit()

            return // return, use only first DMX found
        }
    }
}

extension Entity {
    func forEachModelEntity(block: (ModelEntity) -> Void) {
        recursiveModelEntities().forEach(block)
    }
    func recursiveModelEntities() -> [ModelEntity] {
        if case let m as ModelEntity = self {
            [m] + children.flatMap {$0.recursiveModelEntities()}
        } else {
            children.flatMap {$0.recursiveModelEntities()}
        }
    }
}
extension ModelEntity {
    func mapShaderGraphMaterials(block: (inout ShaderGraphMaterial) -> Void) {
        model!.materials = model!.materials.map {
            if case var m as ShaderGraphMaterial = $0 {
                block(&m)
                return m
            }
            return $0
        }
    }
}
