import Foundation

public struct UTF8Fixed64: RawRepresentable, CustomStringConvertible, Sendable {
    public var rawValue: InlineArray<64, UInt8> = .init(repeating: 0)
    public init(rawValue: RawValue) {self.rawValue = rawValue}
    public init(value: String) {
        self.value = value
    }
    public var value: String! {
        get {String(copying: .init(unchecked: rawValue.span.extracting(first: rawValue.indices.first {rawValue[$0] == 0} ?? RawValue.count)))}
        set {
            let span = newValue.utf8Span.span
            span.extracting(first: RawValue.count).withUnsafeBytes { src in
                withUnsafeMutableBytes(of: &rawValue) { dst in
                    dst.copyBytes(from: src)
                }
            }
        }
    }
    public var description: String {"\"\(value ?? "invalid utf8 \(String(describing: rawValue))")\""}
}
extension UTF8Fixed64: Comparable {
    public static func == (lhs: UTF8Fixed64, rhs: UTF8Fixed64) -> Bool {lhs.value == rhs.value}
    public static func < (lhs: UTF8Fixed64, rhs: UTF8Fixed64) -> Bool {lhs.value < rhs.value}
}
