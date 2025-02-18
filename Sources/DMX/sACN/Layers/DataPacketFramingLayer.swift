import Foundation

/// Framing Layer of Table 4-1: E1.31 Data Packet
///
/// ANSI E1.31 — 2018
/// Entertainment Technology
/// Lightweight streaming protocol for transport
/// of DMX512 using ACN
public struct DataPacketFramingLayer: MemoryMappedPacketOrLayer {
    public static let memoryLayoutSize: Int = 77

    /// Protocol flags and length
    public var flagsAndLength: FlagsAndLength
    /// Identifies 1.31 data as DMP Protocol PDU
    public var vector: MemoryMappedEnum<Vectors.Data>
    /// User Assigned Name of Source:  UTF-8 [UTF-8] encoded string, null-terminated
    public var sourceName: UTF8Fixed64    
    /// priority if multiple sources: 0-200, default of 100
    public var priorityData: UInt8 = 100
    /// Universe address on which sync packets will be sent: Universe on which synchronization packets are transmitted
    public var synchronizationAddress: UInt16BE
    /// Sequence Number To detect duplicate or out of order packets
    public var sequenceNumber: UInt8
    /// Options Flags
    public var options: Options
    public struct Options: RawRepresentable, OptionSet, CustomStringConvertible, Sendable {
        public var rawValue: UInt8
        public init(rawValue: UInt8) {self.rawValue = rawValue}
        /// Preview_Data: Bit 7 (most significant bit): This bit, when set to 1, indicates that the data in this packet is intended for use in visualization or media server preview applications and shall not be used to generate live output.
        public static let previewData = Options(rawValue: 1 << 7)
        /// Stream_Terminated: Bit 6: This bit is intended to allow E1.31 sources to terminate transmission of a stream or of universe synchronization without waiting for a timeout to occur, and to indicate to receivers that such termination is not a fault condition.
        /// When set to 1 in an E1.31 Data Packet, this bit indicates that the source of the data for the universe specified in this packet has terminated transmission of that universe. Three packets containing this bit set to 1 shall be sent by sources upon terminating sourcing of a universe. Upon receipt of a packet containing this bit set to a value of 1, a receiver shall enter network data loss condition. Any property values in an E1.31 Data Packet containing this bit shall be ignored
        public static let streamTerminated = Options(rawValue: 1 << 6)
        /// Force_Synchronization: Bit 5: This bit indicates whether to lock or revert to an unsynchronized state when synchronization is lost (See Section 11 on Universe Synchronization and 11.1 for discussion on synchronization states). When set to 0, components that had been operating in a synchronized state shall not update with any new packets until synchronization resumes. When set to 1, once synchronization has been lost, components that had been operating in a synchronized state need not wait for a new E1.31 Synchronization Packet in order to update to the next E1.31 Data Packet.
        public static let forceSynchronization = Options(rawValue: 1 << 5)

        public var description: String {
            "[" + [
                contains(.previewData) ? "previewData" : nil,
                contains(.streamTerminated) ? "streamTerminated" : nil,
                contains(.forceSynchronization) ? "forceSynchronization" : nil,
            ].compactMap {$0}.joined(separator: ", ") + "]"
        }
    }
    /// Universe Number Identifier for a distinct stream of DMX512-A [DMX] Data
    public var universe: UInt16BE

    public init(flagsAndLength: FlagsAndLength = .init(rawValue: 0x7258), vector: Vectors.Data = .VECTOR_E131_DATA_PACKET, sourceName: UTF8Fixed64, priorityData: UInt8 = 100, synchronizationAddress: UInt16BE = 0, sequenceNumber: UInt8, options: Options = [], universe: UInt16BE) {
        self.flagsAndLength = flagsAndLength
        self.vector = .init(rawValue: vector.rawValue)
        self.sourceName = sourceName
        self.priorityData = priorityData
        self.synchronizationAddress = synchronizationAddress
        self.sequenceNumber = sequenceNumber
        self.options = options
        self.universe = universe
    }
}
