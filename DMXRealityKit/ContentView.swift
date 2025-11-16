import SwiftUI
import RealityKit
import RealityKitContent
import DMX

struct ContentView: View {
    @State private var llTexture: LowLevelTexture = try! .init(descriptor: .init(pixelFormat: .rgba8Unorm, width: DMX.RawValue.count / 4, height: 1, textureUsage: [.shaderRead, .shaderWrite]))
    @State private var textureBuffer: MTLBuffer?
    @State private var dmx = DMX(rawValue: .init(repeating: 0))
    @State private var commandQueue: MTLCommandQueue?

    var body: some View {
        RealityView { content in
            let scene = try! await Entity(named: "Scene", in: realityKitContentBundle)
            content.add(scene)

            // feed DMX to all DMX inputs
            let dmxTexture = try! await TextureResource(from: llTexture)
            scene.children.first!.forEachModelEntity {
                $0.mapShaderGraphMaterials {
                    try? $0.setParameter(name: "DMX", value: .textureResource(dmxTexture))
                    // try! m.setParameter(name: "start", value: .int(4))
                }
            }

            let device = MTLCreateSystemDefaultDevice()!
            textureBuffer = device.makeBuffer(length: DMX.RawValue.count)!
            commandQueue = device.makeCommandQueue()!
        }
        .task(renderLoop)
    }

    private func renderLoop() async {
        while true {
            try! await Task.sleep(for: .milliseconds(10))

            guard let commandBuffer = commandQueue?.makeCommandBuffer(),
                  let blit = commandBuffer.makeBlitCommandEncoder() else { continue }

            // update DMX, typically just copy entire single DMX from another network
            let now = Date().timeIntervalSinceReferenceDate
            dmx.rawValue[0] = UInt8((sin(now) + 1) / 2 * 255)
            dmx.rawValue[1] = UInt8((cos(now) + 1) / 2 * 255)
            dmx.rawValue[4] = UInt8((cos(now * 5) + 1) / 2 * 255)

            // copy DMX into MTLBuffer
            withUnsafeBytes(of: &dmx) {
                textureBuffer?.contents().copyMemory(from: $0.baseAddress!, byteCount: DMX.RawValue.count)
            }
            // copy MTLBuffer into LowLevelTexture
            blit.copy(from: textureBuffer!, sourceOffset: 0, sourceBytesPerRow: DMX.RawValue.count, sourceBytesPerImage: DMX.RawValue.count, sourceSize: .init(width: DMX.RawValue.count / 4, height: 1, depth: 1), to: llTexture.replace(using: commandBuffer), destinationSlice: 0, destinationLevel: 0, destinationOrigin: .init())
            blit.endEncoding()
            commandBuffer.commit()
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

#Preview {
    ContentView()
}
