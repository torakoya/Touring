import MapKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var vm: ContentViewModel
    @EnvironmentObject private var map: MapViewContext
    @State private var showingBookmarked = false
    @State var destinationDetail: DestinationDetail?
    @State var showingDestinationDetail = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack(alignment: .topLeading) {
            GeometryReader { geom in
                MapView()
                    .ignoresSafeArea()
                    .onChange(of: map.heading) { _ in
                        vm.updateCourse()
                    }
                    .onChange(of: geom.size) { _ in
                        if !map.originOnly && map.following {
                            DispatchQueue.main.async {
                                map.setRegionWithDestination(animated: true)
                            }
                        }
                    }
            }

            VStack(alignment: .leading) {
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

                Spacer()

                DestinationPanel()
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
                })
            )
        }

        .onAppear {
            if vm.map == nil { vm.map = map }
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
