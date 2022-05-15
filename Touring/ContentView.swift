import SwiftUI

struct ContentView: View {
    @StateObject var vm = ContentViewModel()
    @State var showingBookmarked = false
    @Environment(\.scenePhase) var scenePhase

    var targetImageName: String {
        if let targetIndex = vm.mapViewContext.targetIndex, targetIndex < 40 {
            return "\(targetIndex + 1).circle"
        } else {
            return "circle"
        }
    }

    var mapModeImageName: String {
        vm.mapViewContext.originOnly ?
            (vm.mapViewContext.following ? "location.square.fill" : "location.square") :
            (vm.mapViewContext.following ? "mappin.square.fill" : "mappin.square")
    }

    var addressText: Text? {
        guard let address = vm.mapViewContext.address else { return nil }

        var ss = address.map { $0.map { Text($0) } }
        ss[1] = ss[1].map { $0.bold() }
        if Locale.current.languageCode != "ja" {
            ss = ss.reversed()
        }

        return joinedText(ss, separator: Text(Locale.current.languageCode == "ja" ? " " : ", "))
    }

    func joinedText(_ texts: [Text?], separator: Text = Text("")) -> Text {
        texts.compactMap { $0 }.flatMap { [separator, $0] }.dropFirst().reduce(Text(""), +)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            GeometryReader { geom in
                MapView(mapViewContext: $vm.mapViewContext)
                    .ignoresSafeArea()
                    .onChange(of: vm.mapViewContext.heading) { _ in
                        vm.updateCourse()
                    }
                    .onChange(of: geom.size) { _ in
                        if !vm.mapViewContext.originOnly && vm.mapViewContext.following {
                            DispatchQueue.main.async {
                                vm.mapViewContext.setRegionWithDestination(animated: true)
                            }
                        }
                    }
            }

            VStack(alignment: .leading) {
                HStack {
                    HStack(alignment: .lastTextBaseline) {
                        Text(vm.speedNumber)
                            .font(.largeTitle.bold())
                            .foregroundColor(vm.isSpeedValid ? Color(uiColor: .label) : .gray)
                        Text(vm.speedUnit)
                            .font(.footnote)
                    }

                    Image(systemName: vm.compassType == .north ? "location.north.circle" : "arrow.up.circle")
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
                .background(Color(uiColor: .systemBackground).opacity(0.4))
                .cornerRadius(15)
                .shadow(radius: 10)
                .padding([.top, .leading, .trailing])

                HStack {
                    Spacer()

                    Button {
                        if !showingBookmarked {
                            showingBookmarked = true
                            vm.location.bookmarkLastLocation()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                showingBookmarked = false
                            }
                        }
                    } label: {
                        Image(systemName: showingBookmarked ? "star.fill" : "star")
                            .font(.largeTitle)
                            .padding()
                    }
                    .disabled(vm.location.last == nil)
                    .background(Color(uiColor: .systemBackground).opacity(0.4))
                    .cornerRadius(15)
                    .shadow(radius: 10)
                    .padding([.leading, .trailing, .bottom])
                }

                Spacer()

                HStack(alignment: .bottom) {
                    if vm.mapViewContext.showsAddress, let addressText = addressText {
                        addressText
                            .shadow(color: Color(uiColor: .systemBackground), radius: 1) // For visibility of the text.
                            .padding(10)
                            .background(Color(uiColor: .systemBackground).opacity(0.4))
                            .cornerRadius(15)
                            .shadow(radius: 10)
                            .allowsHitTesting(false)
                    }

                    Spacer()

                    Button {
                        vm.openSettings()
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.title)
                    }
                    .padding(10)
                    .background(Color(uiColor: .systemBackground).opacity(0.4))
                    .cornerRadius(15)
                    .shadow(radius: 10)
                }.padding([.leading, .trailing])

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
                            .font(.largeTitle)
                    }

                    if let dist = vm.mapViewContext.targetDistance {
                        let diststr = MeasureUtil.distanceString(meters: dist, prefersMile: vm.prefersMile)
                        Text(diststr[0]).bold() + Text(diststr[1]).font(.footnote)
                    }
                }
                .padding()
                .background(Color(uiColor: .systemBackground).opacity(0.4))
                .cornerRadius(15)
                .shadow(radius: 10)
                .padding([.leading, .trailing, .bottom])
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
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                vm.loadSettings()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
