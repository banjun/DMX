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
    private(set) var sourceTransportDescription: String = ""

    // NOTE: when use with TouchDesigner DMX In (sACN) on the same machine, bind fails with 48 (address already in use).
    // workaround: use different port for Sink.
//     let sink = Sink(port: 5569)
    let sink = Sink()
    private(set) var sinkTransportDescription: String = ""

    var dmxs: [[UInt8]] = [
        .init(repeating: 0, count: 512),
        .init(repeating: 0, count: 512),
    ] {
        didSet {
            for i in 0..<dmxs.count {
                guard sinkOrSources[i] == .source else { continue }
                if dmxs[i] != oldValue[i] {
                    setCurrentToSource(index: i)
                }
            }
        }
    }
    var sinkOrSources: [SinkOrSource] = [.source, .sink] {
        didSet {
            for i in 0..<sinkOrSources.count {
                if sinkOrSources[i] != oldValue[i] {
                    // subscribe/unsubscribe on change source/sink
                    let universe = UInt16(i + 1)
                    switch sinkOrSources[i] {
                    case .source, .sourceMultipeer:
                        setCurrentToSource(index: i)
                        Task {await sink.stop(universe: universe)}
                    case .sink:
                        Task {await sink.start(universe: universe)}
                        Task {await source.clear(universe: universe)}
                    }
                }
            }
        }
    }
    enum SinkOrSource: String, Identifiable {
        var id: String {rawValue}
        case sink, source, sourceMultipeer
    }

    // optional: additional transport layer
    @ObservationIgnored private(set) lazy var multipeer = Multipeer()
    @ObservationIgnored private(set) lazy var multipeerSource = Source(transport: .multipeer(multipeer))
    private(set) var multipeerSourceTransportDescription: String = ""

    init() {
        run()
    }

    private func setCurrentToSource(index: Int) {
        Task {await source.set(universe: .init(integerLiteral: UInt16(index + 1)), dmx: dmxs[index])}
    }

    func run() {
        ignoreLocalEndpoints()

        Task {
            await sink.subscribeMultipeer(multipeer.receivedData)
            multipeer.start()

            sourceTransportDescription = await source.transport.description
            multipeerSourceTransportDescription = await multipeerSource.transport.description
            sinkTransportDescription = await sink.port.debugDescription + (sink.isSubscribedMultipeer ? ", multipeer" : "")
        }

        // feed initial source values
        for i in 0..<sinkOrSources.count {
            switch sinkOrSources[i] {
            case .source, .sourceMultipeer: setCurrentToSource(index: i)
            case .sink: Task {await sink.start(universe: UInt16(i + 1))}
            }
        }

        // sink sink.payloads
        Task {
            for await payloads in await sink.payloadsSequence {
                for (universe, payload) in payloads {
                    let i = Int(universe.value - 1)
                    guard i < sinkOrSources.count, sinkOrSources[Int(i)] == .sink else { continue }
                    dmxs[i] = payload.dmx.value
                }
            }
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
