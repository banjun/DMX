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
                            Text("Universe \(universe0Origin + 1)")
                            Picker("", selection: $model.sinkOrSources[universe0Origin]) {
                                Text("Sink").tag(Model.SinkOrSource.sink)
                                Text("Source").tag(Model.SinkOrSource.source)
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
    }
}

#Preview {
    ContentView().environment(Model())
}
