import Foundation

actor UniverseDiscoverySource {
    static let E131_DISCOVERY_UNIVERSE: UInt16BE = 64214
    static let E131_UNIVERSE_DISCOVERY_INTERVAL: TimeInterval = 10
    let cid: RootLayer.CID
    let sourceName: UTF8Fixed64
    let transport: Transport
    let queue: DispatchQueue = .init(label: "\(#file):\(#line)")
    private(set) var encodedPackets: [Data] = []
    private var timer: Task<Void, Never>? {
        didSet {oldValue?.cancel()}
    }

    init(cid: RootLayer.CID, sourceName: UTF8Fixed64, transportDescriptor: Transport.Descriptor) {
        self.cid = cid
        self.sourceName = sourceName
        self.transport = Transport(transportDescriptor, universe: Self.E131_DISCOVERY_UNIVERSE)
        transport.start(queue: queue)
    }

    func setUniverses(universes: [UInt16BE]) {
        encodedPackets = [UniverseDiscoveryPacket](cid: cid, sourceName: sourceName, universes: universes)
            .map {Data(serializing: $0)}
    }

    func submit() {
        encodedPackets.forEach { data in
            transport.send(data: data, debugInfo: nil)
        }
    }
    func run() {
        timer = Task {
            do {
                while true {
                    submit()
                    try await Task.sleep(for: .milliseconds(Self.E131_UNIVERSE_DISCOVERY_INTERVAL * 1000 * 0.9))
                }
            } catch {
                return // should be expected cancel
            }
        }
    }
}
