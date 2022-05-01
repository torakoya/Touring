import SwiftUI

struct ContentView: View {
    @StateObject var vm = ContentViewModel()

    var body: some View {
        ZStack(alignment: .topLeading) {
            MapView(mapViewContext: $vm.mapViewContext)
                .ignoresSafeArea()
                .onChange(of: vm.mapViewContext.heading) { _ in
                    vm.updateCourse()
                }

            HStack {
                HStack(alignment: .lastTextBaseline) {
                    Text(vm.speedNumber)
                        .font(.largeTitle)
                        .foregroundColor(vm.isSpeedValid ? Color(uiColor: .label) : .gray)
                    Text(vm.speedUnit)
                        .font(.footnote)
                }
                .onTapGesture {
                    vm.prefersMile.toggle()
                }

                Image(systemName: "arrow.up.circle")
                    .font(.largeTitle)
                    .rotationEffect(vm.course)
                    .foregroundColor(vm.isCourseValid ? Color(uiColor: .label) : .gray)
                    .padding(.trailing)

                VStack {
                    Text(vm.loggingState == .started ? "Rec" : vm.loggingState == .paused ? "Pause" : "")
                        .font(.caption2.smallCaps().bold())
                        .foregroundColor(vm.loggingState == .paused ? .gray : .red)

                    HStack {
                        Button {
                            if vm.loggingState == .started {
                                vm.location.logger.pause()
                            } else {
                                vm.location.logger.start()
                            }
                        } label: {
                            Image(systemName: vm.loggingState == .started ? "pause.circle" : "record.circle")
                                .font(.title)
                                .foregroundColor(.red)
                        }
                        Button {
                            vm.location.logger.stop()
                        } label: {
                            Image(systemName: "stop.circle")
                                .font(.title)
                        }
                        .disabled(vm.loggingState == .stopped)
                    }
                }
            }
            .padding()
            .background(Color(uiColor: .systemBackground).opacity(0.75))
            .cornerRadius(15)
            .padding()
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
        .alert("main.logging_error.title", isPresented: $vm.alertingLocationLoggingError) {
        } message: {
            Text("main.logging_error.msg")
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
