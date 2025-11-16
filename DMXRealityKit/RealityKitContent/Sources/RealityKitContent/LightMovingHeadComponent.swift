import RealityKit
import simd

// Ensure you register this component in your app’s delegate using:
// LightMovingHeadComponent.registerComponent()
public struct LightMovingHeadComponent: Component, Codable {
    public var pivot: SIMD3<Float> { // SIMD3<Float> build passes, but not supported???
        get {.init(pivotX, pivotY, pivotZ)}
    }
    public var pivotX: Float = 0
    public var pivotY: Float = 0
    public var pivotZ: Float = 0
    public var panMin: Float = -270
    public var panMax: Float = 270
    public var tiltMin: Float = -135
    public var tiltMax: Float = 135

    public init() {}
}
