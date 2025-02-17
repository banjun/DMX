import Foundation

public protocol MemoryMappedPacketOrLayer {
    static var memoryLayoutSize: Int { get }
    static var minMemoryLayoutSize: Int { get }
    var actualMemoryLayoutSize: Int { get }
}
public extension MemoryMappedPacketOrLayer {
    static var minMemoryLayoutSize: Int {Self.memoryLayoutSize}
    var actualMemoryLayoutSize: Int {Self.memoryLayoutSize}

    init!(parsing data: Data, allowingZeroPadding: Bool = false) {
        assert(MemoryLayout<Self>.size == Self.memoryLayoutSize) // make sure memory layout is valid
        let dataToLoad: Data = if allowingZeroPadding {
            data + Data(repeating: UInt8(0), count: max(0, Self.memoryLayoutSize - data.count))
        } else {
            data
        }
        guard dataToLoad.count >= Self.memoryLayoutSize else { return nil }
        self = dataToLoad.withUnsafeBytes {$0.load(as: Self.self)}
    }
}
public extension Data {
    init<T: MemoryMappedPacketOrLayer>(serializing value: T) {
        assert(MemoryLayout<T>.size == T.memoryLayoutSize)
        self = Swift.withUnsafeBytes(of: value) {Data(bytes: $0.baseAddress!, count: value.actualMemoryLayoutSize)}
    }
}
