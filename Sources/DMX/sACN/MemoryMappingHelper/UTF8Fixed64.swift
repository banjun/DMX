import Foundation

public struct UTF8Fixed64: CustomStringConvertible {
    public var rawValue: (CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar) = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    public init(value: String) {
        self.value = value
    }
    public var value: String! {
        get {
            var buffer = ContiguousArray<CChar>(repeating: 0, count: 64 + 1)
            return buffer.withUnsafeMutableBytes { b in
                _ = withUnsafeBytes(of: rawValue) { r in
                    r.copyBytes(to: b, count: 64)
                }
                return String(utf8String: b.assumingMemoryBound(to: CChar.self).baseAddress!)
            }
        }
        set {
            _ = newValue.utf8CString.prefix(64).withUnsafeBytes { v in
                withUnsafeMutableBytes(of: &rawValue) { r in
                    v.copyBytes(to: r, count: v.count)
                }
            }
        }
    }
    public var description: String {"\"\(value ?? "invalid utf8 \(String(describing: rawValue))")\""}
}
