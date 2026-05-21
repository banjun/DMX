import Foundation
import DMX
import Combine

@MainActor @Observable final class Relay {
    let sourceToDevice: Source
    let sourceOnLocal: Source
    let sink: FastSink
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
        didSet {sink.stop(universe: oldValue.value); sink.start(universe: universeFromDevice.value)}
    }
    var universeFromLocal: UInt16BE = 3 {
        didSet {sink.stop(universe: oldValue.value); sink.start(universe: universeFromLocal.value)}
    }
    var universeToLocal: UInt16BE = 4 {
        didSet {Task {await sourceOnLocal.clear(universe: oldValue.value)}}
    }

    private var cancellables: Set<AnyCancellable> = []
    private let measurementsFromDevice: PassthroughSubject<UInt16BE, Never> = .init()
    private let measurementsFromLocal: PassthroughSubject<UInt16BE, Never> = .init()
    private(set) var rates: [UInt16BE: Float] = [:]

    init(sourcePortOnLocal: UInt16 = 5568, sinkPort: UInt16 = 5569, interval: Duration = .milliseconds(1000 / 60)) {
        self.multipeer = .init()
        self.sourceToDevice = .init(transport: .multipeer(multipeer))
        self.sourceOnLocal = .init(transport: .unicast(host: "127.0.0.1", port: sourcePortOnLocal))
        self.sink = .init(port: sinkPort, interval: interval)// avoid collision with TouchDesigner (5568)
        self.sourcePortOnLocal = sourcePortOnLocal
        self.sinkPort = sinkPort
    }

    func run() {
        self.sink.start(universe: universeFromDevice.value)
        self.sink.start(universe: universeFromLocal.value)
        self.sink.subscribeMultipeer(multipeer.receivedData)
        self.multipeer.start()

        measurementsFromDevice.frequency().sink {[weak self] in guard let self else { return }; rates[universeFromDevice] = $0}.store(in: &cancellables)
        measurementsFromLocal.frequency().sink {[weak self] in guard let self else { return }; rates[universeFromLocal] = $0}.store(in: &cancellables)

        self.sink.onReceive = { [weak self] payloads in
            guard let self else { return }
            Task {
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
        return throttle(for: .milliseconds(11), scheduler: RunLoop.main, latest: false) // throttle to suppress too high values
            .measureInterval(using: RunLoop.main)
            .map {1 / Float($0.timeInterval)}
            .merge(with: timeouts)
    }
}
