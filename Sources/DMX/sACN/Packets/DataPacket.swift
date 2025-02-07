import Foundation

/// Table 4-1: E1.31 Data Packet
///
/// ANSI E1.31 — 2018
/// Entertainment Technology
/// Lightweight streaming protocol for transport
/// of DMX512 using ACN
public struct DataPacket: MemoryMappedPacketOrLayer {
    public static let memoryLayoutSize: Int = 638

    public var rootLayer: RootLayer
    public var framingLayer: FramingLayer
    public var dmpLayer: DMPLayer
    
    public init(rootLayer: RootLayer, framingLayer: FramingLayer, dmpLayer: DMPLayer) {
        self.rootLayer = rootLayer
        self.framingLayer = framingLayer
        self.dmpLayer = dmpLayer
    }
}
