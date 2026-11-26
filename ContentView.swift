import SwiftUI

struct ContentView: View {

    @StateObject private var model = AppModel()
    @StateObject private var compass = CompassService()

    @State private var selection: Int = 0

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack {
                LuopanView(model: model, compass: compass)
            }
            .tabItem { Label("罗盘", systemImage: "location.north.line") }
            .tag(0)

            NavigationStack {
                NinePalaceView(chart: model.chart)
            }
            .tabItem { Label("盘面", systemImage: "square.grid.3x3") }
            .tag(1)

            NavigationStack {
                SettingsView(model: model, compass: compass)
            }
            .tabItem { Label("设置", systemImage: "slider.horizontal.3") }
            .tag(2)
        }
        .tint(Palette.gold)
        .preferredColorScheme(.dark)
        .onAppear {
            compass.start()
            if let longitude = compass.longitude {
                model.locationLongitude = longitude
            }
        }
        .onChange(of: compass.longitude) { _, newValue in
            model.locationLongitude = newValue
        }
    }
}

#Preview {
    ContentView()
}
