import Foundation

/// Appendix A: Defined Parameters (Normative)
///
/// ANSI E1.31 — 2018
/// Entertainment Technology
/// Lightweight streaming protocol for transport
/// of DMX512 using ACN
public enum Vectors {
    /// Identifies RLP Data as 1.31 Protocol PDU
    public enum Root: UInt32BE {
        case VECTOR_ROOT_E131_DATA = 0x00000004 // FramingLayer vector is .Data
        case VECTOR_ROOT_E131_EXTENDED = 0x00000008 // FramingLayer vector is .Extended
    }
    public enum Data: UInt32BE {
        /// DMX512-A [DMX] data
        case VECTOR_E131_DATA_PACKET = 0x00000002
    }
    public enum DMP: UInt8 {
        case VECTOR_DMP_SET_PROPERTY = 0x02 // (Informative)
    }
    public enum Extended: UInt32BE {
        case VECTOR_E131_EXTENDED_SYNCHRONIZATION = 0x00000001
        /// universe discovery
        case VECTOR_E131_EXTENDED_DISCOVERY = 0x00000002
    }
    public enum UniverseDiscovery: UInt32BE {
        case VECTOR_UNIVERSE_DISCOVERY_UNIVERSE_LIST = 0x00000001
    }
}
