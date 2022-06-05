import SwiftUI

@main
struct TouringApp: App {
    @StateObject private var map = MapViewContext()
    @StateObject private var vm = ContentViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(map)
                .environmentObject(vm)
        }
    }
}
