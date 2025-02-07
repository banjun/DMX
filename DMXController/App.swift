import SwiftUI

@main
struct DMXControllerApp: App {
    @State private var model: Model = .init()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
        }
        .windowResizability(.contentMinSize)
    }
}
