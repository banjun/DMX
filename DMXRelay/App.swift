import SwiftUI

@main
struct DMXRelayApp: App {
    @State private var model: Relay = .init()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
                .onAppear {model.run()}
        }
        .windowResizability(.contentMinSize)
    }
}
