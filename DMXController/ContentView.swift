import SwiftUI

struct ContentView: View {
    @Environment(Model.self) private var model
    
    var body: some View {
        Grid {
            GridRow {
                ForEach(model.dmxs.indices, id: \.self) { universe0Origin in
                    VStack {
                        HStack {
                            @Bindable var model = model
                            Text("Universe \(universe0Origin + 1)").fixedSize()
                            Picker("", selection: $model.sinkOrSources[universe0Origin]) {
                                Text("Sink (\(model.sinkTransportDescription))").tag(Model.SinkOrSource.sink)
                                Text("Source (\(model.sourceTransportDescription))").tag(Model.SinkOrSource.source)
                                Text("Source (\(model.multipeerSourceTransportDescription))").tag(Model.SinkOrSource.sourceMultipeer)
                            }
                            .fixedSize()
                        }
                        ScrollView(.vertical) {
                            LazyVStack {
                                ForEach(model.dmxs[universe0Origin].indices, id: \.self) { i in
                                    HStack {
                                        Text(String(format: "chan%3d:%3d", i + 1, model.dmxs[universe0Origin][i])).monospaced().fixedSize()
                                        Slider(value: .init(get: {Float(model.dmxs[universe0Origin][i])},
                                                            set: {model.dmxs[universe0Origin][i] = UInt8(round($0))}),
                                               in: 0...255)
                                    }
                                }
                            }
                            .frame(minWidth: 300)
                            .padding()
                        }
                    }
                }
            }
        }
        .padding()
        .modifier(DMXStatusTopOrnamentModifier())
    }
}

struct DMXStatusTopOrnamentModifier: ViewModifier {
    @State private var isExpanded = false
    func body(content: Content) -> some View {
#if os(visionOS)
        content
            .ornament(attachmentAnchor: .scene(.top), contentAlignment: .bottom) {
                Toggle("DMX Status", isOn: $isExpanded).toggleStyle(.button)
                    .glassBackgroundEffect()
                    .padding()
                if isExpanded {
                    UniverseDiscovery()
                        .glassBackgroundEffect()
                        .padding()
                }

            }
#else
        UniverseDiscovery()
        Divider()
        content
#endif
    }
}

#Preview {
    ContentView().environment(Model())
}
