import Foundation
import Network
import MultipeerConnectivity
import Observation

public actor Source {
    public let cid: RootLayer.CID
    public let name: UTF8Fixed64
    public let transport: Transport.Descriptor
    private(set) var connections: [UInt16BE: Connection] = [:]
    let queue: DispatchQueue = .init(label: "\(#file):\(#line)")
    struct Connection {
        var universe: UInt16BE
        var seq: UInt8 = 0
        var transport: Transport
    }
    let scheduler: SourceScheduler = .init()
    public let observable: Observable = .init()
    @Observable public final class Observable: Sendable {
        nonisolated(unsafe) fileprivate var transports: [Transport] = []
        nonisolated(unsafe) public fileprivate(set) var localEndpoints: [NWEndpoint] = []
    }

    public init(name: String = (ProcessInfo().hostName + ":" + ProcessInfo().processName), cid: RootLayer.CID = UUID(), transport: Transport.Descriptor = .sACNMulticast) {
        self.cid = cid
        self.name = .init(value: name)
        self.transport = transport
        Task {await observeTransportLocalEndpoint()}
        Task {
            for await values in scheduler.aggregatedValues {
                values.forEach { universe, dmx in
                    Task {await send(universe: universe, dmx: dmx)}
                }
            }
        }
    }

    public func set(universe: UInt16, dmx: [UInt8]) {
        Task {await scheduler.set(universe: UInt16BE(integerLiteral: universe), dmx: .init(value: dmx))}
    }
    public func clear(universe: UInt16) {
        Task {await scheduler.set(universe: UInt16BE(integerLiteral: universe), dmx: nil)}
    }
    private func send(universe: UInt16BE, dmx: DMX) {
        let universe = universe
        let seq: UInt8
        let transport: Transport

        if var c = connections[universe] {
            c.seq = UInt8((Int(c.seq) + 1) % 256)
            connections[universe] = c
            seq = c.seq
            transport = c.transport
        } else {
            let c = Connection(universe: universe, transport: Transport(self.transport, universe: universe))
            connections[universe] = c
            seq = 0
            transport = c.transport
            transport.start(queue: queue)
            observable.transports.append(transport)
        }

        let packet = DataPacket(
            rootLayer: .init(cid: cid),
            framingLayer: .init(sourceName: name, sequenceNumber: seq, universe: universe),
            dmpLayer: .init(propertyValues: .init(dmx: dmx)))
        let data = Data(serializing: packet)
        transport.send(data: data, debugInfo: (universe, seq))
    }

    private func observeTransportLocalEndpoint() {
        observable.localEndpoints = withObservationTracking {
            observable.transports.compactMap(\.localEndpoint)
        } onChange: {Task {[weak self] in await self?.observeTransportLocalEndpoint()}}
    }
}
