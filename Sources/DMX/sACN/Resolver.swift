import Foundation

struct RawEventValue {
    var universe: UInt16BE
    var dmx: DMX? // nil to clear (it means app is no longer source for universe) for universe
}
typealias AggregatedEventValue = [UInt16BE: DMX]

public protocol Resolver: Sendable {
    @inlinable func resolve(into old: inout DMX, new: DMX)
}
extension Resolver {
    func resolve(reduced: AggregatedEventValue?, value: RawEventValue) -> AggregatedEventValue {
        guard let dmx = value.dmx else {
            if var reduced {
                reduced.removeValue(forKey: value.universe)
                return reduced
            }
            return [:]
        }
        guard var reduced else { return [value.universe: dmx] }
        if reduced[value.universe] != nil {
            resolve(into: &reduced[value.universe]!, new: dmx)
        } else {
            reduced[value.universe] = value.dmx
        }
        return reduced
    }
}

public enum Resolvers {
    public static var newest: some Resolver {Resolvers.Newest()}
    public struct Newest: Resolver {
        @inlinable public func resolve(into old: inout DMX, new: DMX) {
            old.value = new.value
        }
    }

    public static var htp: some Resolver {Resolvers.HighestTakesPrecedence()}
    public struct HighestTakesPrecedence: Resolver {
        @inlinable public func resolve(into old: inout DMX, new: DMX) {
            old.value = zip(old.value, new.value).map(max)
        }
    }
}
