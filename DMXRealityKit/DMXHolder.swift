import RealityKit
import DMX

public protocol DMXHolderType {
    var dmx: DMX { get }
}

public struct DMXHolderComponent: Component {
    var dmxHolder: any DMXHolderType
}

public final class DMXHolder: DMXHolderType {
    public let sink: Sink = .init()
    public let universe: UInt16
    public var dmx: DMX = .init()
    private var observation: Task<Void, Never>? {didSet {oldValue?.cancel()}}
    public init(universe: UInt16) {
        self.universe = universe
    }
    public func start() {
        observation = Task {
            await sink.start(universe: universe)
            for await payload in await sink.payloadsSequence {
                guard let dmx = payload[.init(integerLiteral: universe)]?.dmx else { continue }
                self.dmx = dmx
            }
        }
    }
    public func stop() {
        observation = nil
        Task {await sink.stop(universe: universe)}
    }
}
