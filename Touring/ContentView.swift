import SwiftUI

struct ContentView: View {
    @StateObject var vm = ContentViewModel()

    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            Text(vm.speedNumber)
                .font(.largeTitle)
            Text(vm.speedUnit)
        }
        .onTapGesture {
            vm.prefersMile.toggle()
        }
        .alert("main.location_restricted.title", isPresented: $vm.alertingLocationAuthorizationRestricted) {
        } message: {
            Text("main.location_restricted.msg")
        }
        .alert("main.location_denied.title", isPresented: $vm.alertingLocationAuthorizationDenied) {
            Button("Settings") {
                vm.openSettings()
            }
            Button("OK") {
            }
            .keyboardShortcut(.defaultAction)
        } message: {
            Text("main.location_denied.msg")
        }
        .alert("main.location_reduced.title", isPresented: $vm.alertingLocationAccuracy) {
            Button("Settings") {
                vm.openSettings()
            }
            Button("OK") {
            }
            .keyboardShortcut(.defaultAction)
        } message: {
            Text("main.location_reduced.msg")
        }
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
