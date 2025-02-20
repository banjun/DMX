import Foundation
import Network
@preconcurrency import MultipeerConnectivity
import Observation

@Observable public final class Transport: Sendable {
    private let underlyingTransport: UnderlyingTransport
    enum UnderlyingTransport: Sendable {
        case connection(NWConnection)
        case session(MCSession)
    }
    nonisolated(unsafe) public var localEndpoint: NWEndpoint?

    public enum Descriptor: Sendable, CustomStringConvertible {
        /// sACN standard
        /// 239.255.universeHi.universeLo
        /// on iOS/visionOS device, multicast requires an Apple authorized entitlement
        case sACNMulticast
        /// specific host, mainly for unicast
        case unicast(NWEndpoint)
        public static func unicast(host: String, port: UInt16 = ACN_SDT_MULTICAST_PORT) -> Descriptor {.unicast(.hostPort(host: .init(host), port: .init(rawValue: port)!))}
        /// for example, ("en0", 5568) -> 192.168.0.255:5568
        case directedBroadcast(String?, NWEndpoint.Port)
        public static func directedBroadcast(interface: String? = nil, port: UInt16 = ACN_SDT_MULTICAST_PORT) -> Descriptor {.directedBroadcast(interface, .init(rawValue: port)!)}
        /// universe -> host,port
        case custom(@Sendable (UInt16BE) -> NWEndpoint)
        /// use Multipeer Connectivity in stead of the main interface
        /// TODO: under construction
        case multipeer(Multipeer)

        public var description: String {
            switch self {
            case .sACNMulticast: "sACN 239.255.universeHi.universeLo"
            case .unicast(.hostPort(host: let host, port: let port)): "\(host):\(port)"
            case .unicast: "Unicast"
            case .directedBroadcast(let interface, let port): "DirectedBroadcast:\(port)\(interface.map {"%\($0)"} ?? "")"
            case .custom: "Custom"
            case .multipeer(let multipeer): "Multipeer _\(multipeer.serviceType)"
            }
        }
    }

    public init(_ descriptor: Descriptor, universe: UInt16BE) {
        switch descriptor {
        case .sACNMulticast: underlyingTransport = .connection(.init(sACNUniverse: universe))
        case .unicast(let endpoint): underlyingTransport = .connection(.init(to: endpoint, using: .udp))
        case .directedBroadcast(let name, let port):
            var ifaddrs: UnsafeMutablePointer<ifaddrs>?
            guard getifaddrs(&ifaddrs) == 0, let first = ifaddrs else { fatalError("getifaddrs failed") }
            defer {freeifaddrs(ifaddrs)}
            let dba: String? = sequence(first: first, next: {$0.pointee.ifa_next}).lazy.compactMap { p -> String? in
                let interface = p.pointee
                guard interface.ifa_addr.pointee.sa_family == sa_family_t(AF_INET) else { return nil }
                guard (interface.ifa_flags & UInt32(IFF_BROADCAST)) != 0 else { return nil }
                guard let dst = interface.ifa_dstaddr else { return nil }
                let broadcast = withUnsafePointer(to: dst.pointee) {$0.withMemoryRebound(to: sockaddr_in.self, capacity: 1) {$0.pointee}}
                return inet_ntoa(broadcast.sin_addr).flatMap {String(cString: $0)}
            }.first
            guard let dba else { fatalError("cannot find directed broadcast address. specified interface name = \(String(describing: name))") }
            underlyingTransport = .connection(.init(host: .init(dba), port: port, using: .udp))
        case .custom(let block): underlyingTransport = .connection(.init(to: block(universe), using: .udp))
        case .multipeer(let multipeer): underlyingTransport = .session(multipeer.session)
        }
    }

    func start(queue: DispatchQueue) {
        switch underlyingTransport {
        case .connection(let c): c.start(queue: queue)
        case .session: break
        }
    }

    func send(data: Data, debugInfo: @Sendable @escaping @autoclosure () -> (universe: UInt16BE, seq: UInt8)?) {
        switch underlyingTransport {
        case .connection(let connection):
            connection.send(content: data, completion: .contentProcessed { [weak self] error in
                if self?.localEndpoint != connection.currentPath?.localEndpoint {
                    Task { @MainActor in
                        self?.localEndpoint = connection.currentPath?.localEndpoint
                    }
                }
                if let error {
                    NSLog("%@", "send complettion, debugInfo = \(String(describing: debugInfo())), with error = \(String(describing: error))")
                }
            })
        case .session(let session):
            guard !session.connectedPeers.isEmpty else { return }
            do {
                // NSLog("%@", "sending multipeer")
                try session.send(data, toPeers: session.connectedPeers, with: .unreliable)
            } catch {
                NSLog("%@", "MCSession send error = \(String(describing: error))")
            }
        }
    }
}
