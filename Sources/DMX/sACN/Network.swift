import Foundation
import Network

public let ACN_SDT_MULTICAST_PORT: UInt16 = 5568

@available(macOS 10.14, *)
extension NWConnection {
    public convenience init(sACNUniverse universe: UInt16BE, port: UInt16 = ACN_SDT_MULTICAST_PORT) {
        self.init(to: .init(sACNUniverse: universe, port: port), using: .udp)
    }
}

@available(macOS 10.14, *)
extension NWEndpoint {
    public init(sACNUniverse universe: UInt16BE, port: UInt16 = ACN_SDT_MULTICAST_PORT) {
        self.init(sACNUniverse: universe, port: .init(rawValue: port)!)
    }
    public init(sACNUniverse universe: UInt16BE, port: NWEndpoint.Port) {
        self = .hostPort(host: .init("239.255.\(universe.rawValue.0).\(universe.rawValue.1)"), port: port)
    }
}
