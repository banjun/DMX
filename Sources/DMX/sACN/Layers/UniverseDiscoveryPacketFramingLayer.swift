import Foundation

/// Table 6-7: E1.31 Universe Discovery Packet Framing Layer
///
/// ANSI E1.31 — 2018
/// Entertainment Technology
/// Lightweight streaming protocol for transport
/// of DMX512 using ACN
public struct UniverseDiscoveryPacketFramingLayer: MemoryMappedPacketOrLayer, Sendable {
    public static let memoryLayoutSize: Int = 74

    /// Protocol flags and length
    public var flagsAndLength: FlagsAndLength // 0x7052 - 0x7452
    /// Identifies 1.31 data as Universe Discovery
    public var vector: MemoryMappedEnum<Vectors.Extended>
    public enum Vector: UInt32BE {
        /// (universe discovery
        case VECTOR_E131_EXTENDED_DISCOVERY = 0x00000002
    }
    /// User Assigned Name of Source:  UTF-8 [UTF-8] encoded string, null-terminated
    public var sourceName: UTF8Fixed64
    /// Reserved
    public var reserved: UInt32BE = 0

    public init(flagsAndLength: FlagsAndLength = .init(rawValue: 0x7052), vector: Vector = .VECTOR_E131_EXTENDED_DISCOVERY, sourceName: UTF8Fixed64) {
        self.flagsAndLength = flagsAndLength
        self.vector = .init(rawValue: vector.rawValue)
        self.sourceName = sourceName
    }
}
