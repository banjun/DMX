import Foundation
import AsyncAlgorithms

/// NOTE:
/// > 6.6.2 Null START Code Transmission Requirements in E1.31 Data Packets
/// >
/// > 2. Thereafter, a single keep-alive packet shall be transmitted at intervals of between 800mS and 1000mS.
/// > Each keep-alive packet shall have identical content to the last Null START Code data packet sent with the
/// > exception that the sequence number shall continue to increment normally.
final class SourceScheduler: Sendable {
    private let values: AsyncChannel<RawEventValue> = .init() // TODO: per-universe scheduling?
    var aggregatedValues: some AsyncSequence<AggregatedEventValue, Never> {
        values
            .resolve(resolver: resolver) // TODO: actually not needed for source side. use at sink side
            ._throttle(for: minInterval, clock: clock)
            .replayOnIdle(for: maxInterval, clock: clock)
    }
    let clock: ContinuousClock = .continuous
    let minInterval: ContinuousClock.Duration
    let maxInterval: ContinuousClock.Duration
    let resolver: any Resolver

    init(minInterval: ContinuousClock.Duration = .milliseconds(25), maxInterval: ContinuousClock.Duration = .milliseconds(800), resolver: any Resolver = Resolvers.Newest()) {
        self.minInterval = minInterval
        self.maxInterval = maxInterval
        self.resolver = resolver
    }

    func set(universe: UInt16BE, dmx: DMX?) async {
        await values.send(.init(universe: universe, dmx: dmx))
    }
}

extension AsyncSequence where Self: Sendable, Element == RawEventValue {
    func resolve(resolver: any Resolver) -> some AsyncSequence<AggregatedEventValue, Failure> & Sendable {
        nonisolated(unsafe) var aggregated: AggregatedEventValue?
        return map {
            let v = resolver.resolve(reduced: aggregated, value: $0)
            aggregated = v
            return v
        }
    }
}

extension AsyncSequence where Self: Sendable, Element: Sendable {
    func replayOnIdle<C: Clock>(for interval: C.Instant.Duration, clock: C = .continuous) -> AsyncStream<Element> {
        .init { c in
            Task {
                var timer: Task<Void, Error>?
                defer {
                    timer?.cancel()
                    c.finish()
                }

                for try await value in self {
                    c.yield(value)

                    timer?.cancel()
                    timer = Task {
                        while true {
                            try await Task.sleep(for: interval, clock: clock)
                            try Task.checkCancellation()
                            c.yield(value)
                        }
                    }
                }
            }
        }
    }
}
