import Foundation

public struct UInt16BE: RawRepresentable, CustomStringConvertible, ExpressibleByIntegerLiteral, Sendable {
    public typealias RawValue = (UInt8, UInt8)
    public var rawValue: RawValue
    public init(rawValue: RawValue) {self.rawValue = rawValue}
    public var value: UInt16 {(UInt16(rawValue.0) << 8) | UInt16(rawValue.1)}
    public init(integerLiteral value: UInt16) {
        self.init(rawValue: withUnsafePointer(to: value) {
            let buffer = UnsafeRawPointer($0).assumingMemoryBound(to: UInt8.self)
            return (buffer[1], buffer[0])
        })
    }
    public var description: String {String(describing: value)}
}
extension UInt16BE: Hashable {
    public static func == (lhs: UInt16BE, rhs: UInt16BE) -> Bool {lhs.value == rhs.value}
    public func hash(into hasher: inout Hasher) {value.hash(into: &hasher)}
}
extension UInt16BE: Comparable {
    public static func < (lhs: UInt16BE, rhs: UInt16BE) -> Bool {lhs.value < rhs.value}
}
