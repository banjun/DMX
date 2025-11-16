import RealityKit

// Ensure you register this component in your app’s delegate using:
// DMXReceiverComponent.registerComponent()
public struct DMXReceiverComponent: Component, Codable {
    public var start: Int32 = 0

    public init() {
    }
}
