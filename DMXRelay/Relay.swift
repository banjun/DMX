import Foundation
import DMX
import Combine

@MainActor @Observable final class Relay {
    let sourceToDevice: Source
    let sourceOnLocal: Source
    let sink: Sink
    let multipeer: Multipeer
    let sourcePortOnLocal: UInt16
    let sinkPort: UInt16

    // example configuration:
    // Device U1 <--MCSession-- Relay <--localhost:5569-- U3 TouchDesigner
    // Device U2 --MCSession--> Relay --localhost:5568--> U4 TouchDesigner
    var universeToDevice: UInt16BE = 1 {
        didSet {Task {await sourceToDevice.clear(universe: oldValue.value)}}
    }
    var universeFromDevice: UInt16BE = 2 {
        didSet {Task {await sink.stop(universe: oldValue.value); await sink.start(universe: universeFromDevice.value)}}
    }
    var universeFromLocal: UInt16BE = 3 {
        didSet {Task {await sink.stop(universe: oldValue.value); await sink.start(universe: universeFromLocal.value)}}
    }
    var universeToLocal: UInt16BE = 4 {
        didSet {Task {await sourceOnLocal.clear(universe: oldValue.value)}}
    }

    private var cancellables: Set<AnyCancellable> = []
    private let measurementsFromDevice: PassthroughSubject<UInt16BE, Never> = .init()
    private let measurementsFromLocal: PassthroughSubject<UInt16BE, Never> = .init()
    private(set) var rates: [UInt16BE: Float] = [:]

    init(sourcePortOnLocal: UInt16 = 5568, sinkPort: UInt16 = 5569) {
        self.multipeer = .init()
        self.sourceToDevice = .init(transport: .multipeer(multipeer))
        self.sourceOnLocal = .init(transport: .unicast(host: "127.0.0.1", port: sourcePortOnLocal))
        self.sink = .init(port: sinkPort)// avoid collision with TouchDesigner (5568)
        self.sourcePortOnLocal = sourcePortOnLocal
        self.sinkPort = sinkPort
    }

    func run() {
        Task {
            await self.sink.start(universe: universeFromDevice.value)
            await self.sink.start(universe: universeFromLocal.value)
            await self.sink.subscribeMultipeer(multipeer.receivedData)
            self.multipeer.start()

            measurementsFromDevice.frequency().sink {[weak self] in guard let self else { return }; rates[universeFromDevice] = $0}.store(in: &cancellables)
            measurementsFromLocal.frequency().sink {[weak self] in guard let self else { return }; rates[universeFromLocal] = $0}.store(in: &cancellables)

            for await payloads in await self.sink.payloadsSequence {
                if let payload = payloads[universeFromDevice] {
                    measurementsFromDevice.send(universeFromDevice)

                    await sourceOnLocal.set(universe: universeToLocal.value, dmx: payload.dmx.value)
                }
                if let payload = payloads[universeFromLocal] {
                    measurementsFromLocal.send(universeFromLocal)

                    await sourceToDevice.set(universe: universeToDevice.value, dmx: payload.dmx.value)
                }
            }
        }
    }
}

extension Publisher {
    func frequency() -> some Publisher<Float, Failure> {
        let timeouts = debounce(for: 1, scheduler: RunLoop.main).map {_ in Float(0)}
        return measureInterval(using: RunLoop.main)
            .map {1 / Float($0.timeInterval)}
            .merge(with: timeouts)
    }
}
