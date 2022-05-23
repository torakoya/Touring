import MapKit
import SwiftUI

struct ContentView: View {
    @StateObject var vm = ContentViewModel()
    @State var showingBookmarked = false
    @State var showingPlaceSearch = false
    @Environment(\.scenePhase) var scenePhase
    @State var searchResult: PlaceSearchResult?

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

    var isRouteButtonDisabled: Bool {
        vm.mapViewContext.mapView?.userLocation.location == nil || vm.mapViewContext.target == nil
    }

    var isRouteButtonExpanded: Bool {
        vm.mapViewContext.showingRoutes &&
        (routeDistanceString != nil || routeTimeString != nil)
    }

    var routeDistanceString: [String]? {
        if vm.mapViewContext.showingRoutes, let routes = vm.mapViewContext.routes {
            return MeasureUtil.distanceString(meters: routes.distance, prefersMile: vm.prefersMile)

        } else {
            return nil
        }
    }

    var routeTimeString: [String]? {
        if vm.mapViewContext.showingRoutes, let routes = vm.mapViewContext.routes {
            return [String(Int(routes.time / 60 / 60)), String(Int(routes.time / 60) % 60)]
        } else {
            return nil
        }
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

                    VStack(spacing: 0) {
                        Text(vm.loggingState == .started ? "Rec" : vm.loggingState == .paused ? "Pause" : "")
                            .font(.caption2.smallCaps().bold())
                            .foregroundColor(vm.loggingState == .paused ? .gray : .red)

                        Menu {
                            Button {
                                showingPlaceSearch = true
                            } label: {
                                Label("Search Place", systemImage: "magnifyingglass")
                            }
                            Button {
                            } label: {
                                Label("Destination List", systemImage: "list.bullet")
                            }

                            Divider()

                            if vm.loggingState != .started {
                                // This is not destructive, but should
                                // be paid attention. And this
                                // "destructive" is also intended to
                                // make it red, the same as common
                                // record buttons are.
                                Button(role: .destructive) {
                                    vm.location.logger.start()
                                } label: {
                                    Label(vm.loggingState == .paused ?
                                          "Resume Location Tracking" :
                                            "Start Location Tracking",
                                          systemImage: "record.circle.fill")
                                }
                            } else {
                                Button {
                                    vm.location.logger.pause()
                                } label: {
                                    Label("Pause Location Tracking", systemImage: "pause.circle")
                                }
                            }
                            if vm.loggingState != .stopped {
                                Button {
                                    vm.location.logger.stop()
                                } label: {
                                    Label("Stop Location Tracking", systemImage: "stop.circle")
                                }
                            }

                            Divider()

                            Button {
                                UIApplication.shared.openSettings()
                            } label: {
                                Label("Settings", systemImage: "gearshape")
                            }
                            Button {
                            } label: {
                                Label("Help", systemImage: "questionmark")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.title)
                                .foregroundColor(vm.loggingState == .started ? .red : Color(uiColor: .link))
                        }
                    }
                }
                .panel()
                .padding([.top, .leading, .trailing])

                HStack {
                    HStack {
                        Button {
                            vm.mapViewContext.showingRoutes.toggle()
                        } label: {
                            Image(systemName: vm.mapViewContext.showingRoutes ? "eye" : "eye.slash")
                                .font(.largeTitle)
                                .padding(isRouteButtonExpanded ? [.top, .bottom, .leading] : .all)
                        }
                        .disabled(isRouteButtonDisabled)

                        if isRouteButtonExpanded {
                            VStack(alignment: .leading) {
                                if let dist = routeDistanceString {
                                    Text(dist[0]).bold() + Text(dist[1]).font(.footnote)
                                } else {
                                    Text("")
                                }
                                if let time = routeTimeString {
                                    Text(time[0]).bold() + Text("h ").font(.footnote) +
                                    Text(time[1]).bold() + Text("m").font(.footnote)
                                } else {
                                    Text("")
                                }
                            }
                            .padding(.trailing)
                        }
                    }
                    .panel(padding: 0)
                    .padding([.leading, .trailing, .bottom])

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
                    .panel(padding: 0)
                    .padding([.leading, .trailing, .bottom])
                }

                Spacer()

                HStack(alignment: .bottom) {
                    if vm.mapViewContext.showsAddress, let addressText = addressText {
                        addressText
                            .shadow(color: Color(uiColor: .systemBackground), radius: 1) // For visibility of the text.
                            .panel(padding: 10)
                            .allowsHitTesting(false)
                    }

                    Spacer()
                }.padding([.leading, .trailing])

                HStack {
                    Button {
                        vm.mapViewContext.goBackward()
                    } label: {
                        Image(systemName: "chevron.backward.2")
                            .font(.title)
                    }
                    .disabled(vm.mapViewContext.destinations.count <= 1)
                    Image(systemName: targetImageName)
                        .font(.title)
                    Button {
                        vm.mapViewContext.goForward()
                    } label: {
                        Image(systemName: "chevron.forward.2")
                            .font(.title)
                    }
                    .disabled(vm.mapViewContext.destinations.count <= 1)
                    .padding(.trailing, 10)

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
                .panel()
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
                UIApplication.shared.openSettings()
            }
            Button("OK") {
            }
            .keyboardShortcut(.defaultAction)
        } message: {
            Text("main.location_denied.msg")
        }
        .alert("main.location_reduced.title", isPresented: $vm.alertingLocationAccuracy) {
            Button("Settings") {
                UIApplication.shared.openSettings()
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
        .sheet(isPresented: $showingPlaceSearch) {
            PlaceSearchView(result: $searchResult)
        }
        .onChange(of: searchResult) {
            if let searchResult = $0, let mapView = vm.mapViewContext.mapView {
                // Keep the span, just change the center.
                var region = mapView.region
                region.center = searchResult.mapItem.placemark.coordinate
                mapView.setRegion(region, animated: true)

                if searchResult.action == .pin {
                    let ann = MKPointAnnotation()
                    ann.coordinate = searchResult.mapItem.placemark.coordinate
                    ann.title = searchResult.mapItem.name
                    vm.mapViewContext.destinations += [ann]
                    try? MapUtil.saveDestinations(vm.mapViewContext.destinations)
                }

                self.searchResult = nil
            }
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
