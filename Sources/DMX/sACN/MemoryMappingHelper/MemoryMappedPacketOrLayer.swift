import Foundation

public protocol MemoryMappedPacketOrLayer {
    static var memoryLayoutSize: Int { get }
}
public extension MemoryMappedPacketOrLayer {
    init!(parsing data: Data) {
        assert(MemoryLayout<Self>.size == Self.memoryLayoutSize)
        guard data.count >= Self.memoryLayoutSize else { return nil }
        self = data.withUnsafeBytes {$0.load(as: Self.self)}
    }
}
public extension Data {
    init<T: MemoryMappedPacketOrLayer>(serializing value: T) {
        assert(MemoryLayout<T>.size == T.memoryLayoutSize)
        self = Swift.withUnsafeBytes(of: value) {Data(bytes: $0.baseAddress!, count: T.memoryLayoutSize)}
    }
}
