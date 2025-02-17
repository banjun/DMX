import Foundation

/// Table 8-9: E1.31 Universe Discovery Packet Universe Discovery Layer
///
/// ANSI E1.31 — 2018
/// Entertainment Technology
/// Lightweight streaming protocol for transport
/// of DMX512 using ACN
public struct UniverseDiscoveryLayer: MemoryMappedPacketOrLayer {
    public static let memoryLayoutSize: Int = 1032

    /// Protocol flags and length
    public var flagsAndLength: FlagsAndLength // 0x7008 - 0x7408
    /// Identifies Universe Discovery data as universe list
    public var vector: MemoryMappedEnum<Vector>
    public enum Vector: UInt32BE {
        case VECTOR_UNIVERSE_DISCOVERY_UNIVERSE_LIST = 0x00000001
    }
    /// Packet Number: Identifier indicating which packet of N this is—pages start numbering at 0.
    public var page: UInt8
    /// Final Page: Page number of the final page to be transmitted.
    public var lastPage: UInt8
    /// Sorted list of up to 512 16-bit universes.: Universes upon which data is being transmitted.
    /// in Swift: Fixed 512 * UInt16BE
    var listOfUniversesFixed1024: (UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE, UInt16BE) = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    public var listOfUniversesCount: Int {Int(flagsAndLength.pduLength - 8)}
    public var listOfUniverses: [UInt16BE] {
        get {
            withUnsafeBytes(of: listOfUniversesFixed1024) {
                $0.prefix(listOfUniversesCount).withMemoryRebound(to: UInt16BE.self) {
                    Array($0)
                }
            }
        }
        set {
            _ = newValue.withUnsafeBytes { v in
                let listOfUniversesCount = listOfUniversesCount
                withUnsafeMutableBytes(of: &listOfUniversesFixed1024) { r in
                    v.copyBytes(to: r, count: listOfUniversesCount)
                }
            }
        }
    }

    public init(flagsAndLength: FlagsAndLength, vector: Vector = .VECTOR_UNIVERSE_DISCOVERY_UNIVERSE_LIST, page: UInt8, lastPage: UInt8, listOfUniverses: [UInt16BE]) {
        self.flagsAndLength = flagsAndLength
        self.vector = .init(rawValue: vector.rawValue)
        self.page = page
        self.lastPage = lastPage
        self.listOfUniverses = listOfUniverses
    }
    public init(page: UInt8, lastPage: UInt8, listOfUniverses: [UInt16BE]) {
        self.init(flagsAndLength: .init(pduLength: UInt16(8 + MemoryLayout<UInt16BE>.size * listOfUniverses.count)), page: page, lastPage: lastPage, listOfUniverses: listOfUniverses)
    }
}
