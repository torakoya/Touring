import SwiftUI

struct MenuButton: View {
    @EnvironmentObject private var vm: ContentViewModel
    @EnvironmentObject private var map: MapViewContext
    @State private var showingPlaceSearch = false
    @State private var showingDestinationList = false
    @State private var showingDestinationSetList = false
    @State private var showingHelp = false
    @State private var searchResult: PlaceSearchResult?
    @State private var destinationListResult: DestinationListView.Result?
    private let contactMailaddr = Bundle.main.object(forInfoDictionaryKey: "CONTACT_MAILADDR") as? String

    var body: some View {
        Menu {
            Button {
                showingPlaceSearch = true
            } label: {
                Label("Search for Place", systemImage: "magnifyingglass")
            }
            Button {
                showingDestinationList = true
            } label: {
                Label("Destination List", systemImage: "list.bullet")
            }
            .disabled(DestinationSet.current.destinations.isEmpty)
            Button {
                showingDestinationSetList = true
            } label: {
                Label("Switch Destination Set", systemImage: "list.bullet.below.rectangle")
            }
            .disabled(DestinationSet.current.isEmpty && DestinationSet.others.isEmpty)

            Divider()

            if vm.loggingState != .started {
                // This is not destructive, but should be paid attention.
                // And this "destructive" is also intended to make it
                // red, the same as common record buttons are.
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
                showingHelp = true
            } label: {
                Label("Help", systemImage: "questionmark")
            }
            if let contactMailaddr = contactMailaddr, !contactMailaddr.isEmpty {
                Button {
                    let note = String(localized: "contact.info.note")
                    // Line breaks in a body must be CR+LF (RFC 2368).
                    let body = """
                        ---\r
                        \(note)\r
                        app: \(Bundle.main.name ?? "-")\r
                        ver: \(Bundle.main.fullVersion ?? "-")\r
                        device: \(UIDevice.current.machine)\r
                        system: \(UIDevice.current.systemVersion)\r
                        ---\r
                        \r\n
                        """.addingPercentEncoding(withAllowedCharacters: .urlQueryDataAllowed)
                    if let url = URL(string: "mailto:\(contactMailaddr)?body=\(body ?? "")") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Contact (Email)", systemImage: "envelope")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title)
                .foregroundColor(vm.loggingState == .started ? .red : Color(uiColor: .link))
        }

        .sheet(isPresented: $showingPlaceSearch) {
            PlaceSearchView(result: $searchResult, region: map.mapView?.region)
        }
        .onChange(of: searchResult) {
            if let searchResult = $0 {
                map.setCenter(searchResult.mapItem.placemark.coordinate, animated: true)

                if searchResult.action == .pin {
                    let dest = Destination()
                    dest.coordinate = searchResult.mapItem.placemark.coordinate
                    dest.title = searchResult.mapItem.name
                    DestinationSet.current.destinations += [dest]
                    try? DestinationSet.saveAll()
                }

                self.searchResult = nil
            }
        }

        .sheet(isPresented: $showingDestinationList) {
            DestinationListView(result: $destinationListResult)
        }
        .onChange(of: destinationListResult) {
            if let result = $0 {
                map.setCenter(result.destination.coordinate, animated: true)
                destinationListResult = nil
            }
        }

        .sheet(isPresented: $showingDestinationSetList) {
            DestinationSetListView()
        }
        .sheet(isPresented: $showingHelp) {
            HelpView()
        }
    }
}

struct MenuButton_Previews: PreviewProvider {
    static var previews: some View {
        MenuButton()
            .environmentObject(ContentViewModel())
    }
}
