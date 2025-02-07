import Foundation

public struct UInt32BE: RawRepresentable, CustomStringConvertible, ExpressibleByIntegerLiteral, Sendable {
    public typealias RawValue = (UInt8, UInt8, UInt8, UInt8)
    public var rawValue: RawValue
    public init(rawValue: RawValue) {self.rawValue = rawValue}
    public var value: UInt32 {UInt32(rawValue.0) << 24 | UInt32(rawValue.1) << 16 | UInt32(rawValue.2) << 8 | UInt32(rawValue.3)}
    public init(integerLiteral value: UInt32) {
        self.init(rawValue: withUnsafePointer(to: value) {
            let buffer = UnsafeRawPointer($0).assumingMemoryBound(to: UInt8.self)
            return (buffer[3], buffer[2], buffer[1], buffer[0])
        })
    }
    public var description: String {String(describing: value)}
}
extension UInt32BE: Hashable {
    public static func == (lhs: UInt32BE, rhs: UInt32BE) -> Bool {lhs.value == rhs.value}
    public func hash(into hasher: inout Hasher) {value.hash(into: &hasher)}
}
