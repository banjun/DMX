import Foundation
import Network
import Combine
import os

public final class FastSink: Sendable {
    private nonisolated(unsafe) var _payloads: OSAllocatedUnfairLock<[UInt16BE: Sink.Payload]> = .init(initialState: [:])
    public private(set) var payloads: [UInt16BE: Sink.Payload] {
        get {_payloads.withLock {$0}}
        set {_payloads.withLock {$0 = newValue}}
    }
    private func setResolvingPayload(universe: UInt16BE, payload: Sink.Payload) {
        _payloads.withLock { payloads in
            // NOTE: resolver not yet implemented because FastSink has no throttle
            payloads[universe] = payload
            onReceive?(payloads)
        }
    }
    public nonisolated(unsafe) var onReceive: (([UInt16BE: Sink.Payload]) -> Void)?

    private nonisolated(unsafe) var connectionGroup: NWConnectionGroup? {
        didSet {oldValue?.cancel()}
    }
    private nonisolated(unsafe) var multicastGroup: NWMulticastGroup? {
        didSet {
            NSLog("%@", "multicastGroup.members = \(String(describing: multicastGroup?.members))")
            if let multicastGroup {
                let params = NWParameters.udp
                params.allowLocalEndpointReuse = true
                params.allowFastOpen = true
                connectionGroup = NWConnectionGroup(with: multicastGroup, using: params)
            } else {
                connectionGroup = nil
            }
        }
    }
    private let queue: DispatchQueue = .init(label: "\(#file):\(#line)", qos: .userInteractive)
    public let port: NWEndpoint.Port
    private nonisolated(unsafe) var ignoredRemoteEndpoints: [NWEndpoint] = []
    public func set(ignoredRemoteEndpoints: [NWEndpoint]) {self.ignoredRemoteEndpoints = ignoredRemoteEndpoints}

    private let resolver: any Resolver

    public init(port: UInt16 = ACN_SDT_MULTICAST_PORT, ignoredRemoteEndpoints: @escaping () -> [NWEndpoint] = {[]}, interval: ContinuousClock.Instant.Duration = .milliseconds(25), resolver: any Resolver = Resolvers.newest) {
        self.port = .init(rawValue: port)!
        self.ignoredRemoteEndpoints = ignoredRemoteEndpoints()
        self.resolver = resolver
        // not yet ported from Sink: self.recentPayloadsStream = .init {_ in} // dummy for init
        // not yet ported from Sink: self.universeDiscoveryStream = .init {_ in} // dummy for initc
        // not yet ported from Sink: Task {await setupRecentPayloadsStream()}
        // not yet ported from Sink: Task {await setupIniverseDiscoveryStream()}
    }

    private nonisolated(unsafe) var buffers: [UInt16BE: Data?] = [:]
    public func start(universe: UInt16) {
        let universe: UInt16BE = .init(integerLiteral: universe)

        let endpoint = NWEndpoint(sACNUniverse: universe, port: port)
        if let multicastGroup {
            guard !multicastGroup.members.contains(endpoint) else { return }
        }
        // re-create connection group, as adding multicast group is not supported
        //
        // NOTE: this approach is rather useless, because adding to multicast group always fails.
        // > nw_listener_socket_inbox_create_socket IP_DROP_MEMBERSHIP 239.255.0.1:5568 failed [49: Can't assign requested address]
        self.multicastGroup = try! NWMulticastGroup(for: (multicastGroup?.members ?? []) + [endpoint])
        guard let connectionGroup else { return }

        connectionGroup.setReceiveHandler { [weak self] message, data, isCompleted in
            guard let self, let data else { return }
            receiveFromNWConnection(message: message, data: data, isCompleted: isCompleted)
        }
        connectionGroup.stateUpdateHandler = { state in
            // NOTE: when use with TouchDesigner DMX In (sACN) on the same machine, bind fails with 48 (address already in use). workaround: use different port for Sink.
            NSLog("%@", "connection for universe \(universe), state = \(state)")
            switch state {
            case .failed, .cancelled: break // another universe can cancel the other. ignored: Task {await self.stop(universe: universe.value)}
            case .setup, .ready, .waiting: break
            @unknown default: break
            }
        }

        connectionGroup.start(queue: queue)
    }

    private nonisolated(unsafe) var multipeerReceiverCancellable: AnyCancellable?
    private nonisolated(unsafe) var multipeerReceiver: (any Publisher<Data, Never>)? {
        didSet {
            multipeerReceiverCancellable = multipeerReceiver?.sink { [weak self] data in
                self?.parseDataOrDiscovery(data: data, pathDescription: "Multipeer")
            }
        }
    }
    public var isSubscribedMultipeer: Bool {multipeerReceiver != nil}
    public func subscribeMultipeer(_ receiveData: any Publisher<Data, Never>) {
        self.multipeerReceiver = receiveData
    }
    public func unsubscribeMultipper() {
        self.multipeerReceiver = nil
    }

    private func receiveFromNWConnection(message: NWConnectionGroup.Message, data: Data, isCompleted: Bool) {
        if let remoteEndpoint = message.remoteEndpoint {
            guard !self.ignoredRemoteEndpoints.contains(remoteEndpoint) else {
                // NSLog("%@", "ignored: receive from \(remoteEndpoint)")
                return
            }
        }

        let universeToMatch: UInt16BE?
        var buffer: Data
        if case .hostPort(host: .ipv4(let v4host), port: _) = message.localEndpoint,
           v4host.rawValue[0] == 239, v4host.rawValue[1] == 255, UInt16BE(rawValue: (v4host.rawValue[2], v4host.rawValue[3])) != UniverseDiscoverySource.E131_DISCOVERY_UNIVERSE {
            let universe = UInt16BE(rawValue: (v4host.rawValue[2], v4host.rawValue[3]))
            universeToMatch = universe

            buffer = buffers[universe, default: Data()]!
            buffer.append(data)
            buffers[universe] = buffer
            guard isCompleted else { return }
            buffers[universe] = nil
        } else {
            universeToMatch = nil
            guard isCompleted else {
                NSLog("%@", "cannot verify universe from \(String(describing: message.localEndpoint)). in this case, we expect the packet is complete but isCompleted = \(isCompleted). ignored.")
                return
            }
            buffer = data
        }

        parseDataOrDiscovery(data: buffer, universeToMatch: universeToMatch, pathDescription: message.localEndpoint?.debugDescription ?? "unknown network")
    }

    private func parseDataOrDiscovery(data buffer: Data, universeToMatch: UInt16BE? = nil, pathDescription: String) {
        guard buffer.count >= RootLayer.memoryLayoutSize, let rootLayer = RootLayer(parsing: buffer) else {
            NSLog("%@", "buffer.count \(buffer.count) should be equal (or greater) than RootLayer \(RootLayer.memoryLayoutSize) bytes")
            return
        }

        switch rootLayer.vector.value {
        case .VECTOR_ROOT_E131_DATA?: break // nominal
        case .VECTOR_ROOT_E131_EXTENDED?:
            // process universe discovery
// NOTE: not yet ported from Sink
//            guard buffer.count >= UniverseDiscoveryPacket.minMemoryLayoutSize else {
//                NSLog("%@", "buffer.count \(buffer.count) should be equal (or greater) than \(UniverseDiscoveryPacket.minMemoryLayoutSize) bytes")
//                return
//            }
//            guard let packet = UniverseDiscoveryPacket(parsing: buffer, allowingZeroPadding: true) else {
//                NSLog("%@", "buffer is not universe discovery packet") // possibly Synchronization Packet
//                return
//            }
//            universeDiscoveryStreamContinuation?.yield((packet, pathDescription))
            return // do not hold as data packet
        case nil:
            NSLog("%@", "unknown RootLayer.vector = \(rootLayer.vector)")
            return
        }

        guard buffer.count >= DataPacket.memoryLayoutSize else {
            NSLog("%@", "buffer.count \(buffer.count) should be equal (or greater) than \(DataPacket.memoryLayoutSize) bytes")
            return
        }

        guard let packet = DataPacket(parsing: buffer) else {
            NSLog("%@", "unknown DataPacket(parsing: buffer) error for buffer: \(buffer.map {String(format: "%02X", $0)}.joined(separator: " "))")
            return
        }

        if let universeToMatch {
            guard packet.framingLayer.universe == universeToMatch else {
                NSLog("%@", "packet.framingLayer.universe should be = \(universeToMatch) but \(packet.framingLayer.universe) on this connection. path = \(pathDescription))")
                return
            }
        }

        checkAndHold(packet: packet)
    }

    func checkAndHold(packet: DataPacket) {
        let payloads = self.payloads
        let universe = UInt16BE(integerLiteral: packet.framingLayer.universe.value)
        let seq = packet.framingLayer.sequenceNumber
        if let lastPayload = payloads[universe] {
            let lastSeq = lastPayload.seq
            guard ((Int(seq) - Int(lastSeq)) & 0xFF) < ((Int(lastSeq) - Int(seq)) & 0xFF) else {
                NSLog("%@", "seq should progress old \(lastSeq) -> new \(seq)")
                return
            }
        }

        let sync = packet.framingLayer.synchronizationAddress
        if sync != 0, payloads[UInt16BE(integerLiteral: sync.value)] == nil {
            NSLog("TODO: universe \(packet.framingLayer.universe) requires synchronization on \(sync) but it's not yet implemented")
            // TODO: ensure listen to the universe, Task {await start(universe: sync.value)}
            // TODO: bring {throttle | buffer and await sync} branch to the pipeline
            // TODO: flush the pipeline on a sync packet
        }

        let payload = Sink.Payload(packet: packet)
        setResolvingPayload(universe: universe, payload: payload)
        // NOTE: not yet ported from Sink: recentPayloadsStreamContinuation?.yield(payload)
    }

    public func stop(universe: UInt16) {
        let universe: UInt16BE = .init(integerLiteral: universe)
        let endpoint = NWEndpoint(sACNUniverse: universe, port: port)
        guard var members = multicastGroup?.members, let i = members.firstIndex(of: endpoint) else { return }
        members.remove(at: i)
        multicastGroup = members.isEmpty ? nil : try! NWMulticastGroup(for: members)
    }
}
