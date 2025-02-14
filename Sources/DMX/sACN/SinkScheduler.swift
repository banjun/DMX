import Foundation
import AsyncAlgorithms

final class SinkScheduler {
    private var payloadStream: AsyncStream<Sink.Payload>
    private var payloadStreamContinuation: AsyncStream<Sink.Payload>.Continuation?
    var payloadsSequence: some AsyncSequence<[UInt16BE: Sink.Payload], Never> & Sendable {
        let resolver = self.resolver
        return payloadStream
            ._throttle(for: interval, clock: .continuous) { reduced, payload in
                guard var reduced else { return [payload.universe: payload] }
                if reduced[payload.universe] != nil {
                    resolver.resolve(into: &reduced[payload.universe]!.dmx, new: payload.dmx)
                } else {
                    reduced[payload.universe] = payload
                }
                return reduced
            }
    }

    let interval: ContinuousClock.Instant.Duration
    let resolver: any Resolver

    init(interval: ContinuousClock.Instant.Duration, resolver: any Resolver) {
        self.interval = interval
        self.resolver = resolver
        self.payloadStream = .init {_ in} // dummy for init
        self.payloadStream = .init {payloadStreamContinuation = $0}
    }

    func receive(payload: Sink.Payload) {
        payloadStreamContinuation?.yield(payload)
    }
}
