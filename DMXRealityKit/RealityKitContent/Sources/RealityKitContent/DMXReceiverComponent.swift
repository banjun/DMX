import RealityKit

// Ensure you register this component in your app’s delegate using:
// DMXReceiverComponent.registerComponent()
public struct DMXReceiverComponent: Component, Codable {
    // 1-origin start channel
    public var start: Int32 = 1

    public init() {
    }
}
