import Foundation

public struct DMX: RawRepresentable, Sendable {
    public var rawValue: InlineArray<512, UInt8> = .init(repeating: 0)
    public init() {}
    public init(rawValue: RawValue) {self.rawValue = rawValue}
    public init(value: [UInt8]) {
        assert(value.count == RawValue.count)
        self.value = value
    }
    public var value: [UInt8] {
        get {withUnsafeBytes(of: rawValue) {Array($0)}}
        set {
            assert(newValue.count == RawValue.count)
            withUnsafeMutableBytes(of: &rawValue) { r in
                r.copyBytes(from: newValue)
            }
        }
    }
}
