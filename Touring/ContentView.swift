import SwiftUI

struct ContentView: View {
    @StateObject var vm = ContentViewModel()

    var targetImageName: String {
        if let targetIndex = vm.mapViewContext.targetIndex, targetIndex < 40 {
            return "\(targetIndex + 1).circle"
        } else {
            return "circle"
        }
    }

    var mapModeImageName: String {
        vm.mapViewContext.originOnly ?
            (vm.mapViewContext.following ? "o.square.fill" : "o.square") :
            (vm.mapViewContext.following ? "flag.square.fill" : "flag.square")
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            MapView(mapViewContext: $vm.mapViewContext)
                .ignoresSafeArea()
                .onChange(of: vm.mapViewContext.heading) { _ in
                    vm.updateCourse()
                }

            VStack(alignment: .leading) {
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

                Spacer()

                HStack {
                    Button {
                        vm.mapViewContext.goBackward()
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.title)
                    }
                    .disabled(vm.mapViewContext.destinations.count <= 1)
                    Image(systemName: targetImageName)
                        .font(.title)
                    Button {
                        vm.mapViewContext.goForward()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.title)
                    }
                    .disabled(vm.mapViewContext.destinations.count <= 1)
                    Button {
                        if vm.mapViewContext.following {
                            if vm.mapViewContext.destinations.isEmpty {
                                vm.mapViewContext.originOnly = true
                            } else {
                                vm.mapViewContext.originOnly.toggle()
                            }
                        } else {
                            vm.mapViewContext.following.toggle()
                        }
                    } label: {
                        Image(systemName: mapModeImageName)
                            .font(.title)
                    }

                    if let dist = vm.mapViewContext.targetDistance {
                        let diststr = MeasureUtil.distanceString(meters: dist, prefersMile: vm.prefersMile)
                        Text(diststr[0]) + Text(diststr[1]).font(.footnote)
                    }
                }
                .padding()
                .background(Color(uiColor: .systemBackground).opacity(0.75))
                .cornerRadius(15)
                .padding()
                .padding(.bottom, 10) // Avoid covering MKmapView's legal label
            }
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
        .onChange(of: vm.mapViewContext.selectedDestination) { newValue in
            if newValue >= 0 {
                vm.destinationDetail = DestinationDetail(
                    vm.mapViewContext.destinations[newValue],
                    at: newValue,
                    onUpdate: { dest in
                        vm.mapViewContext.destinations[dest.id].title = (dest.title.isEmpty ? nil : dest.title)
                        try? MapUtil.saveDestinations(vm.mapViewContext.destinations)
                    },
                    onRemove: { dest in
                        vm.mapViewContext.destinations.remove(at: dest.id)
                        try? MapUtil.saveDestinations(vm.mapViewContext.destinations)
                    })
                vm.showingDestinationDetail = true
            }
        }
        .sheet(isPresented: $vm.showingDestinationDetail) {
            vm.mapViewContext.selectedDestination = -1
        } content: {
            DestinationDetailView(dest: Binding($vm.destinationDetail)!)
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
