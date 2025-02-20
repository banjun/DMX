import SwiftUI

struct ContentView: View {
    @Environment(Relay.self) private var model
    var body: some View {
        Divider()
        Grid {
            GridRow {
                Text("Universe \(model.universeToDevice)").fontWeight(.bold)
                Text("<-- Multipeer Connectivity --").fixedSize()
                if let rate = model.rates[model.universeFromLocal], rate != 0 {
                    Text("\(String(format: "%2.1f Hz", rate))").monospacedDigit().fontWeight(.bold)
                } else {
                    Image(systemName: "app").frame(width: 20)
                }
                Text("<-- localhost:\(model.sinkPort, format: .number.grouping(.never)) --").fixedSize()
                Text("Universe \(model.universeFromLocal.value)").fontWeight(.bold)
            }
            GridRow {
                Text("")
                Divider()
                Divider()
                Divider()
                Text("")
            }
            GridRow {
                Text("Universe \(model.universeFromDevice)").fontWeight(.bold)
                Text("-- Multipeer Connectivity -->").fixedSize()
                if let rate = model.rates[model.universeFromDevice], rate != 0 {
                    Text("\(String(format: "%2.1f Hz", rate))").monospacedDigit().fontWeight(.bold)
                } else {
                    Image(systemName: "app").frame(width: 20)
                }
                Text("-- localhost:\(model.sourcePortOnLocal, format: .number.grouping(.never)) -->").fixedSize()
                Text("Universe \(model.universeToLocal)").fontWeight(.bold)
            }
        }
        .fixedSize()
        .padding()
        Divider()
    }
}

#Preview {
    ContentView()
}
