import SwiftUI
import RealityKit
import RealityKitContent
import DMX

struct ContentView: View {
    @State private var dmxHolder: DMXHolder = .init(universe: 1)

    var body: some View {
        RealityView { content in
            DMXTextureUpdateSystem.registerSystemAndComponents()
            let scene = try! await Entity(named: "Scene", in: realityKitContentBundle)
            content.add(scene)

            let dmxHolderEntity = Entity()
            dmxHolderEntity.components.set(DMXHolderComponent(dmxHolder: dmxHolder))
            content.add(dmxHolderEntity)
        }
        .onAppear {dmxHolder.start()}
        .onDisappear {dmxHolder.stop()}
    }
}

#Preview {
    ContentView()
}
