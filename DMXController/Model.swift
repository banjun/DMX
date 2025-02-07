import Foundation
import Observation
import DMX

@MainActor @Observable final class Model {
    // NOTE: multicast from iOS/visionOS device requires an Apple authorized entitlement for that
    // https://developer.apple.com/contact/request/networking-multicast
    // workaround: try unicast or directed broadcast for developer test
//    let source = Source(transport: .unicast(host: "192.168.0.1"))
//    let source = Source(transport: .directedBroadcast())
#if os(macOS) || targetEnvironment(simulator)
    let source = Source()
#else
    let source = Source(transport: .directedBroadcast())
#endif

    // NOTE: when use with TouchDesigner DMX In (sACN) on the same machine, bind fails with 48 (address already in use).
    // workaround: use different port for Sink.
//     let sink = Sink(port: 5569)
    let sink = Sink()

    var dmxs: [[UInt8]] = [
        .init(repeating: 0, count: 512),
        .init(repeating: 0, count: 512),
    ]
    var sinkOrSources: [SinkOrSource] = [.source, .sink]
    enum SinkOrSource: String, Identifiable {
        var id: String {rawValue}
        case sink, source
    }

    init() {
        run()
    }

    func run() {
        ignoreLocalEndpoints()

        Task.detached {
            for _ in 0..<100_000 {
                for (universe0Origin, sinkOrSource) in await self.sinkOrSources.enumerated() {
                    let universe = UInt16(universe0Origin + 1)
                    switch sinkOrSource {
                    case .sink:
                        await self.sink.start(universe: universe)
                        if let payload = await self.sink.payloads[universe], let dmx = payload?.dmx.value {
                            Task { @MainActor [weak self] in self?.dmxs[universe0Origin] = dmx }
                        }
                    case .source:
                        await self.sink.stop(universe: universe)
                        await self.source.send(universe: universe, dmx: self.dmxs[universe0Origin])
                    }
                }
                try! await Task.sleep(for: .milliseconds(1000 / 30))
            }
            NSLog("%@", "finished loop for Demo app")
        }
    }

    // effective when using directed broadcast on source
    private func ignoreLocalEndpoints() {
        Task {await observeLocalEndpoints()}
    }
    private func observeLocalEndpoints() async {
        let observable = await source.observable
        await sink.set(ignoredRemoteEndpoints: withObservationTracking {
            observable.localEndpoints
        } onChange: {
            Task {[weak self] in await self?.observeLocalEndpoints()}
        })
    }
}
