import SwiftUI
import DMX

struct UniverseDiscovery: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                DiscoveredUniverses()
                Divider()
                RecentPayloads()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .padding()
    }

    struct DiscoveredUniverses: View {
        @Environment(Model.self) private var model
        var body: some View {
            VStack(alignment: .leading) {
                Text("Universe Discovery (\(model.universeDiscovery.count) sources)").font(.footnote)
                ForEach(model.universeDiscovery, id: \.0) { uuid, name, path, universes in
                    HStack {
                        if !universes.isEmpty {
                            Text(try! AttributedString(markdown: "**\(universes)** sourced by " + name.value + " via \(path)")).font(.body)
                        } else {
                            Text("\(name) via \(path)").font(.body).foregroundStyle(.quaternary)
                        }
                    }
                }
            }
            .task {model.startUniverseDiscovery()}
        }
    }

    struct RecentPayloads: View {
        @Environment(Model.self) private var model
        var body: some View {
            VStack(alignment: .leading) {
                Text("Recent Payloads").font(.footnote)
                ScrollView(.vertical) {
                    Grid(alignment: .leading) {
                        ForEach(model.recentPayloads.keys.sorted(), id: \.self) { universe in
                            //                            HStack(alignment: .top, spacing: 4) {
                            GridRow(alignment: .top) {
                                Text("Universe \(universe)").font(.body).fixedSize()
                                VStack(alignment: .leading) {
                                    ForEach(Array(model.recentPayloads[universe]!.values), id: \.1.cid) { date, payload in
                                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                                            FadeOutIndicator(date: date) {
                                                Circle().foregroundStyle(.green).frame(width: 8, height: 8)
                                            }
                                            Text("\(payload.source)").font(.body).foregroundStyle(.secondary)
                                                .frame(minWidth: 150)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        struct FadeOutIndicator<Content: View>: View {
            @State private var opacity: Double = 1
            var date: Date
            var duration: TimeInterval = 1
            @ViewBuilder var content: () -> Content
            var body: some View {
                content().opacity(opacity).onChange(of: date, initial: true) {_, _ in
                    opacity = 1
                    withAnimation(.spring(duration: duration)) {opacity = 0}
                }
            }
        }
    }
}

#Preview {
    UniverseDiscovery()
        .environment(Model())
}

#Preview {
    VStack(alignment: .leading) {
        HStack {
            VStack(alignment: .leading) {
                Text("Universe Discovery (- sources)").font(.footnote)
                Text("1")
                Text("2")
                Text("3")
            }
            VStack(alignment: .leading) {
                Text("Recent RecentPayloads").font(.footnote)
                ScrollView(.vertical) {
                    TimelineView(.animation(minimumInterval: 0.1)) {
                        Circle().foregroundStyle(.green).frame(width: 8, height: 8)
                            .opacity(1 - Date().timeIntervalSince($0.date) / 5)
                    }
                    Text("A")
                    Text("B")
                    Text("C")
                    Text("D")
                    Text("E")
                    Text("F")
                }
            }
        }
    }
    .frame(width: 300)
    Divider()
    Color.blue.frame(height: 300)
}
