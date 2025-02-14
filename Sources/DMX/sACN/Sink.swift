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
        public var dmx: DMX
        init(packet: DataPacket) {
            self.universe = packet.framingLayer.universe
            self.seq = packet.framingLayer.sequenceNumber
            self.source = packet.framingLayer.sourceName.value
            self.dmx = packet.dmpLayer.propertyValues.dmx
        }
    }

    public init(port: UInt16 = ACN_SDT_MULTICAST_PORT, ignoredRemoteEndpoints: @escaping () -> [NWEndpoint] = {[]}, interval: ContinuousClock.Instant.Duration = .milliseconds(25), resolver: any Resolver = Resolvers.newest) {
        self.port = .init(rawValue: port)!
        self.ignoredRemoteEndpoints = ignoredRemoteEndpoints()
        self.scheduler = .init(interval: interval, resolver: resolver)
    }

    private var buffers: [UInt16BE: Data?] = [:]
    public func start(universe: UInt16) async {
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
                await checkAndHold(message: message, data: data, isCompleted: isCompleted)
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

    private var multipeerReceiverCancellable: AnyCancellable?
    private var multipeerReceiver: (any Publisher<Data, Never>)? {
        didSet {
            multipeerReceiverCancellable = multipeerReceiver?.sink { [weak self] data in
                guard let self else { return }
                Task {
                    guard let packet = DataPacket(parsing: data) else {
                        NSLog("%@", "unknown DataPacket(parsing: buffer) error for buffer: \(data.map {String(format: "%02X", $0)}.joined(separator: " "))")
                        return
                    }
                    await self.checkAndHold(packet: packet)
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

    private func checkAndHold(message: NWConnectionGroup.Message, data: Data, isCompleted: Bool) {
        if let remoteEndpoint = message.remoteEndpoint {
            guard !self.ignoredRemoteEndpoints.contains(remoteEndpoint) else {
                // NSLog("%@", "ignored: receive from \(remoteEndpoint)")
                return
            }
        }

        let universeToMatch: UInt16BE?
        var buffer: Data
        if case .hostPort(host: .ipv4(let v4host), port: _) = message.localEndpoint,
           v4host.rawValue[0] == 239, v4host.rawValue[1] == 255 {
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
                NSLog("%@", "packet.framingLayer.universe should be = \(universeToMatch) but \(packet.framingLayer.universe) on this connection. local = \(String(describing: message.localEndpoint?.debugDescription))")
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

        let payload = Payload(packet: packet)
        payloads[packet.framingLayer.universe.value] = payload
        scheduler.receive(payload: payload)
    }

    public func stop(universe: UInt16) {
        let universe: UInt16BE = .init(integerLiteral: universe)
        let endpoint = NWEndpoint(sACNUniverse: universe, port: port)
        guard var members = multicastGroup?.members, let i = members.firstIndex(of: endpoint) else { return }
        members.remove(at: i)
        multicastGroup = members.isEmpty ? nil : try! NWMulticastGroup(for: members)
    }
}
