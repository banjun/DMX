import Foundation

/// Root Layer of Table 4-1: E1.31 Data Packet
///
/// ANSI E1.31 — 2018
/// Entertainment Technology
/// Lightweight streaming protocol for transport
/// of DMX512 using ACN
public struct RootLayer: MemoryMappedPacketOrLayer, Sendable {
    public static let memoryLayoutSize: Int = 38

    /// Define RLP Preamble Size.
    public var preambleSize: UInt16BE = 0x0010 // constant
    /// RLP Post-amble Size.
    public var postambleSize: UInt16BE = 0x0000 // constant
    /// Identifies this packet as E1.17
    public var acnPacketIdentifier: (UInt32BE, UInt32BE, UInt32BE) = (0x4153432d, 0x45312e31, 0x37000000)
    /// Protocol flags and length
    public var flagsAndLength: FlagsAndLength
    /// Identifies RLP Data as 1.31 Protocol PDU
    public var vector: MemoryMappedEnum<Vector>
    /// Identifies RLP Data as 1.31 Protocol PDU
    public enum Vector: UInt32BE {
        case VECTOR_ROOT_E131_DATA = 0x00000004
        case VECTOR_ROOT_E131_EXTENDED = 0x00000008
    }
    /// Sender's CID (Sender's unique ID)
    public var cid: CID
    public typealias CID = UUID // 16 bytes ... (UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE)

    public init(preambleSize: UInt16BE = 0x0010, postambleSize: UInt16BE = 0x0000, acnPacketIdentifier: (UInt32BE, UInt32BE, UInt32BE) = (0x4153432d, 0x45312e31, 0x37000000), flagsAndLength: FlagsAndLength = .init(rawValue: 0x700B), vector: Vector = .VECTOR_ROOT_E131_DATA, cid: CID) {
        self.preambleSize = preambleSize
        self.postambleSize = postambleSize
        self.acnPacketIdentifier = acnPacketIdentifier
        self.flagsAndLength = flagsAndLength
        self.vector = .init(rawValue: vector.rawValue)
        self.cid = cid
    }
}
