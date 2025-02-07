import Foundation

public struct MemoryMappedEnum<Enum: RawRepresentable>: CustomStringConvertible, Sendable where Enum.RawValue: Sendable {
    public var rawValue: Enum.RawValue
    public init (rawValue: Enum.RawValue) {self.rawValue = rawValue}
    public var value: Enum! {.init(rawValue: rawValue)}
    public var description: String {value.map {String(describing: $0)} ?? "MemoryMappedEnum(invalid rawValue = \(rawValue)"}
}
