import SwiftUI

struct ContentView: View {
    @StateObject var vm = ContentViewModel()

    var body: some View {
        Text("Hello, world!")
            .padding()
            .alert("Location access is restricted", isPresented: $vm.alertingLocationAuthorizationRestricted) {
            } message: {
                Text("This app cannot use your location by some restrictions such as parental controls.")
            }
            .alert("Location access is denied", isPresented: $vm.alertingLocationAuthorizationDenied) {
                Button("Settings") {
                    vm.openSettings()
                }
                Button("OK") {
                }
                .keyboardShortcut(.defaultAction)
            } message: {
                Text("Allow this app to use your location or turn on Location Services for this device.")
            }
            .alert("Location accuracy is reduced", isPresented: $vm.alertingLocationAccuracy) {
                Button("Settings") {
                    vm.openSettings()
                }
                Button("OK") {
                }
                .keyboardShortcut(.defaultAction)
            } message: {
                Text("Allow this app to get your specific location.")
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
