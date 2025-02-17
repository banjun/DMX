import Foundation

/// Table 4-3: E1.31 Universe Discovery Packet Format
///
/// ANSI E1.31 — 2018
/// Entertainment Technology
/// Lightweight streaming protocol for transport
/// of DMX512 using ACN
public struct UniverseDiscoveryPacket: MemoryMappedPacketOrLayer {
    public static let memoryLayoutSize: Int = 1144 // max
    public static let minMemoryLayoutSize: Int = 120
    public var actualMemoryLayoutSize: Int {
        RootLayer.memoryLayoutSize + UniverseDiscoveryPacketFramingLayer.memoryLayoutSize + Int(universeDiscoveryLayer.flagsAndLength.pduLength)
    }

    public var rootLayer: RootLayer
    public var framingLayer: UniverseDiscoveryPacketFramingLayer
    public var universeDiscoveryLayer: UniverseDiscoveryLayer

    public init(rootLayer: RootLayer, framingLayer: UniverseDiscoveryPacketFramingLayer, universeDiscoveryLayer: UniverseDiscoveryLayer) {
        self.rootLayer = rootLayer
        self.framingLayer = framingLayer
        self.universeDiscoveryLayer = universeDiscoveryLayer
    }
    public init(cid: RootLayer.CID, sourceName: UTF8Fixed64, universeDiscoveryLayer: UniverseDiscoveryLayer) {
        let universeDiscoveryLayerPDULength: UInt16 = universeDiscoveryLayer.flagsAndLength.pduLength
        self.init(
            rootLayer: .init(flagsAndLength: .init(pduLength: universeDiscoveryLayerPDULength + 112 + 96), cid: cid),
            framingLayer: .init(flagsAndLength: .init(pduLength: universeDiscoveryLayerPDULength + 112 + 74), sourceName: sourceName),
            universeDiscoveryLayer: universeDiscoveryLayer)
    }
}
