import RealityKit
import simd

// Ensure you register this component in your app’s delegate using:
// LightMovingHeadComponent.registerComponent()
public struct LightMovingHeadComponent: Component, Codable {
//    public var pivot: SIMD3<Float> = .zero // buid passes, but not supported???
    public var panMin: Float = -270
    public var panMax: Float = 270
    public var tiltMin: Float = -135
    public var tileMax: Float = 135

    public init() {}
}
