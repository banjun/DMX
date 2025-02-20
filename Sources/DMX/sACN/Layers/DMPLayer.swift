import Foundation

/// DMP Layer of Table 4-1: E1.31 Data Packet
/// 
/// ANSI E1.31 — 2018
/// Entertainment Technology
/// Lightweight streaming protocol for transport
/// of DMX512 using ACN
public struct DMPLayer: MemoryMappedPacketOrLayer {
    public static let memoryLayoutSize: Int = 523

    /// Protocol flags and length
    public var flagsAndLength: FlagsAndLength
    ///
    public var vector: MemoryMappedEnum<Vectors.DMP>
    ///
    public var addressTypeAndDataType: UInt8 = 0xa1
    public var firstProopertyAddress: UInt16BE = 0x0000
    public var addressIncrement: UInt16BE = 0x0001
    public var propertyValueCount: UInt16BE // 0x0001 -- 0x0201
    public var propertyValues: PropertyValue
    public struct PropertyValue {
        public var startCode: MemoryMappedEnum<StartCode>
        public enum StartCode: UInt8 {
            case normal = 0x00
        }
        public var dmx: DMX
        
        public init(startCode: StartCode = .normal, dmx: DMX) {
            self.startCode = .init(rawValue: startCode.rawValue)
            self.dmx = dmx
        }
    }

    public init(flagsAndLength: FlagsAndLength = .init(rawValue: 0x720B), vector: Vectors.DMP = .VECTOR_DMP_SET_PROPERTY, addressTypeAndDataType: UInt8 = 0xA1, firstProopertyAddress: UInt16BE = 0, addressIncrement: UInt16BE = 1, propertyValueCount: UInt16BE = 513, propertyValues: PropertyValue) {
        self.flagsAndLength = flagsAndLength
        self.vector = .init(rawValue: vector.rawValue)
        self.addressTypeAndDataType = addressTypeAndDataType
        self.firstProopertyAddress = firstProopertyAddress
        self.addressIncrement = addressIncrement
        self.propertyValueCount = propertyValueCount
        self.propertyValues = propertyValues
    }
}
