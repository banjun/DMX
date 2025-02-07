import Foundation

public struct FlagsAndLength: RawRepresentable, CustomStringConvertible, Sendable {
    public var rawValue: UInt16BE
    public init(rawValue: UInt16BE) {self.rawValue = rawValue}
    public var flag: UInt8 {UInt8(rawValue.value >> 12)} // 0b0111
    public var pduLength: UInt16 {
        get {rawValue.value & 0x0FFF}
        set {rawValue = .init(rawValue: (UInt8(flag << 4) | UInt8((newValue >> 8) & 0x0F), UInt8(newValue & 0xFF)))}
    }
    public var description: String {"(flag: \(flag), pduLength: \(pduLength))"}
}
