import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var vm: ContentViewModel
    @EnvironmentObject private var map: MapViewContext
    @State private var showingBookmarked = false
    @State var destinationDetail: DestinationDetail?
    @State var showingDestinationDetail = false
    @State var showingStatus = false
    @Environment(\.scenePhase) private var scenePhase

    private var isStatusBarHidden: Bool {
        UIApplication.shared.keyWindow?.windowScene?.statusBarManager?.isStatusBarHidden ?? false
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            MapView()
                .ignoresSafeArea()
                .onChange(of: map.heading) { _ in
                    vm.updateCourse()
                }

            GeometryReader { geom in
                HStack {
                    if showingStatus {
                        Spacer()
                        StatusPanel()
                    }
                }
                .onChange(of: geom.safeAreaInsets) { _ in
                    showingStatus = isStatusBarHidden
                }
            }

            VStack(alignment: .leading) {
                if !(vm.map?.movingDestination ?? false) {
                    SpeedPanel()
                        .padding([.top, .leading, .trailing])

                    if map.showsAddress {
                        AddressPanel()
                            .padding([.leading, .trailing])
                    }

                    HStack {
                        RouteButton()
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
                }

                Spacer()

                if vm.map?.movingDestination ?? false {
                    HStack {
                        Button("Cancel") {
                            vm.map?.endMovingDestination()
                        }
                        .padding(.trailing)
                        Button("Move") {
                            vm.map?.moveDestination()
                            try? DestinationSet.saveAll()
                            vm.map?.endMovingDestination()
                        }
                        Spacer()
                        Button("Satellite") {
                            if let mapView = vm.map?.mapView {
                                if mapView.mapType == .standard {
                                    mapView.mapType = .hybrid
                                } else {
                                    mapView.mapType = .standard
                                }
                                vm.objectWillChange.send()
                            }
                        }
                        .font(.body.weight(vm.map?.mapView?.mapType == .hybrid ? .bold : .regular))
                    }
                    .panel()
                    .padding()
                    .padding(.bottom, 10) // Avoid covering MKmapView's legal label
                } else {
                    DestinationPanel()
                        .padding([.leading, .trailing, .bottom])
                        .padding(.bottom, 10) // Avoid covering MKmapView's legal label
                }
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

        .onChange(of: map.selectedDestination) { newValue in
            if newValue >= 0 {
                showingDestinationDetail = true
            }
        }
        .sheet(isPresented: $showingDestinationDetail) {
            map.selectedDestination = -1
        } content: {
            DestinationDetailView(dest: DestinationDetail(
                DestinationSet.current.destinations[map.selectedDestination],
                at: map.selectedDestination,
                onUpdate: { dest in
                    DestinationSet.current.destinations[dest.id].title = (dest.title.isEmpty ? nil : dest.title)
                    try? DestinationSet.saveAll()
                },
                onRemove: { dest in
                    DestinationSet.current.destinations.remove(at: dest.id)
                    try? DestinationSet.saveAll()
                },
                onMove: { dest in
                    vm.map?.startMovingDestination(at: dest.id)
                })
            )
        }

        .onAppear {
            if vm.map == nil { vm.map = map }
            showingStatus = isStatusBarHidden
            UIApplication.shared.isIdleTimerDisabled = true
        }
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
