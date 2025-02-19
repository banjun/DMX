import Foundation
import Network
import Combine

public actor Sink {
    public private(set) var payloads: [UInt16: Payload?] = [:]

    let scheduler: SinkScheduler
    public var payloadsSequence: some AsyncSequence<[UInt16BE: Payload], Never> & Sendable {scheduler.payloadsSequence}

    private var connectionGroup: NWConnectionGroup? {
        didSet {oldValue?.cancel()}
    }
    private var multicastGroup: NWMulticastGroup? {
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
    private let queue: DispatchQueue = .init(label: "\(#file):\(#line)")
    public let port: NWEndpoint.Port
    private var ignoredRemoteEndpoints: [NWEndpoint] = []
    public func set(ignoredRemoteEndpoints: [NWEndpoint]) {self.ignoredRemoteEndpoints = ignoredRemoteEndpoints}

    public struct Payload: Sendable {
        public var universe: UInt16BE
        public var seq: UInt8
        public var source: String
        public var cid: RootLayer.CID
        public var dmx: DMX
        init(packet: DataPacket) {
            self.universe = packet.framingLayer.universe
            self.seq = packet.framingLayer.sequenceNumber
            self.source = packet.framingLayer.sourceName.value
            self.cid = packet.rootLayer.cid
            self.dmx = packet.dmpLayer.propertyValues.dmx
        }
    }

    public init(port: UInt16 = ACN_SDT_MULTICAST_PORT, ignoredRemoteEndpoints: @escaping () -> [NWEndpoint] = {[]}, interval: ContinuousClock.Instant.Duration = .milliseconds(25), resolver: any Resolver = Resolvers.newest) {
        self.port = .init(rawValue: port)!
        self.ignoredRemoteEndpoints = ignoredRemoteEndpoints()
        self.scheduler = .init(interval: interval, resolver: resolver)
        self.recentPayloadsStream = .init {_ in} // dummy for init
        self.universeDiscoveryStream = .init {_ in} // dummy for initc
        Task {await setupRecentPayloadsStream()}
        Task {await setupIniverseDiscoveryStream()}
    }
    private func setupRecentPayloadsStream() {
        self.recentPayloadsStream = .init {recentPayloadsStreamContinuation = $0}
    }
    private func setupIniverseDiscoveryStream() {
        self.universeDiscoveryStream = .init {universeDiscoveryStreamContinuation = $0}
    }

    private var buffers: [UInt16BE: Data?] = [:]
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
            Task {
                await receiveFromNWConnection(message: message, data: data, isCompleted: isCompleted)
            }
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
    public func startUniverseDiscovery() {
        start(universe: UniverseDiscoverySource.E131_DISCOVERY_UNIVERSE.value)
    }

    private var multipeerReceiverCancellable: AnyCancellable?
    private var multipeerReceiver: (any Publisher<Data, Never>)? {
        didSet {
            multipeerReceiverCancellable = multipeerReceiver?.sink { [weak self] data in
                guard let self else { return }
                Task {
                    await self.parseDataOrDiscovery(data: data, pathDescription: "Multipeer")
                }
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
            guard buffer.count >= UniverseDiscoveryPacket.minMemoryLayoutSize else {
                NSLog("%@", "buffer.count \(buffer.count) should be equal (or greater) than \(UniverseDiscoveryPacket.minMemoryLayoutSize) bytes")
                return
            }
            guard let packet = UniverseDiscoveryPacket(parsing: buffer, allowingZeroPadding: true) else {
                NSLog("%@", "buffer is not universe discovery packet") // possibly Synchronization Packet
                return
            }
            universeDiscoveryStreamContinuation?.yield((packet, pathDescription))
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
        let seq = packet.framingLayer.sequenceNumber
        if let lastPayload = payloads[packet.framingLayer.universe.value], let lastSeq = lastPayload?.seq {
            guard ((Int(seq) - Int(lastSeq)) & 0xFF) < ((Int(lastSeq) - Int(seq)) & 0xFF) else {
                NSLog("%@", "seq should progress old \(lastSeq) -> new \(seq)")
                return
            }
        }

        let sync = packet.framingLayer.synchronizationAddress
        if sync != 0, payloads[sync.value] == nil {
            NSLog("TODO: universe \(packet.framingLayer.universe) requires synchronization on \(sync) but it's not yet implemented")
            // TODO: ensure listen to the universe, Task {await start(universe: sync.value)}
            // TODO: bring {throttle | buffer and await sync} branch to the pipeline
            // TODO: flush the pipeline on a sync packet
        }

        let payload = Payload(packet: packet)
        payloads[packet.framingLayer.universe.value] = payload
        scheduler.receive(payload: payload)
        recentPayloadsStreamContinuation?.yield(payload)
    }

    public func stop(universe: UInt16) {
        let universe: UInt16BE = .init(integerLiteral: universe)
        let endpoint = NWEndpoint(sACNUniverse: universe, port: port)
        guard var members = multicastGroup?.members, let i = members.firstIndex(of: endpoint) else { return }
        members.remove(at: i)
        multicastGroup = members.isEmpty ? nil : try! NWMulticastGroup(for: members)
    }

    // MARK: - Observation for Network Status

    private var recentPayloadsStream: AsyncStream<Payload>
    private var recentPayloadsStreamContinuation: AsyncStream<Payload>.Continuation?
    public var recentPayloadsSequence: some AsyncSequence<[UInt16BE: [RootLayer.CID: (Date, Payload)]], Never> & Sendable {
        var payloads: [UInt16BE: [RootLayer.CID: (Date, Payload)]] = [:]
        let expire: TimeInterval = 10
        return recentPayloadsStream.map {
            let now = Date()
            payloads = payloads.mapValues {$0.filter {now.timeIntervalSince($0.value.0) < expire}}.filter {!$0.value.isEmpty}
            var p = payloads[$0.universe, default: [:]]
            p[$0.cid] = (now, $0)
            payloads[$0.universe] = p
            return payloads
        }._throttle(for: .milliseconds(0.1), latest: true)
    }

    private var universeDiscoveryStream: AsyncStream<(UniverseDiscoveryPacket, String)>
    private var universeDiscoveryStreamContinuation: AsyncStream<(UniverseDiscoveryPacket, String)>.Continuation?
    public var universeDiscoverySequence: some AsyncSequence<[RootLayer.CID: (UTF8Fixed64, String, [UInt16BE])], Never> & Sendable {
        var activePackets: [(Date, UniverseDiscoveryPacket, String)] = []
        return universeDiscoveryStream.map { v in
            let now = Date()
            activePackets = activePackets.filter {now.timeIntervalSince($0.0) < UniverseDiscoverySource.E131_UNIVERSE_DISCOVERY_INTERVAL}
            activePackets.append((now, v.0, v.1))
            return activePackets.map {($0.1, $0.2)}
        }.map { (activePackets: [(UniverseDiscoveryPacket, String)]) in
            [RootLayer.CID: [(UniverseDiscoveryPacket, String)]](grouping: activePackets) {
                $0.0.rootLayer.cid
            }
            .mapValues { (packets: [(UniverseDiscoveryPacket, String)]) in
                let universes: Set<UInt16BE> = .init(packets.flatMap(\.0.universeDiscoveryLayer.listOfUniverses))
                return (packets.first!.0.framingLayer.sourceName, packets.first!.1, Array(universes).sorted())
            }
        }
    }
}
