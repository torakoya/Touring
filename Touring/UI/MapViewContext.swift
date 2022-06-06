import Combine
import MapKit

/// The information of a map view that the parent view may want.
class MapViewContext: ObservableObject {
    weak var mapView: MKMapView?

    @Published var heading: CLLocationDirection = 0

    @Published var selectedDestination: Int = -1

    @Published var following = false {
        didSet {
            if let mapView = mapView {
                if originOnly {
                    mapView.setUserTrackingMode(following ? .follow : .none, animated: true)
                } else if following {
                    setRegionWithDestination()
                }
            }
        }
    }
    @Published var originOnly = true {
        didSet {
            if let mapView = mapView {
                if originOnly && following {
                    mapView.setUserTrackingMode(.follow, animated: true)
                } else {
                    mapView.setUserTrackingMode(.none, animated: true)

                    if !originOnly && following {
                        setRegionWithDestination()
                    }
                }
            }
        }
    }

    var targetDistance: CLLocationDistance? {
        if let mapView = mapView, let target = DestinationSet.current.target {
            let user = mapView.userLocation.coordinate
            let dest = target.coordinate
            let userloc = CLLocation(latitude: user.latitude, longitude: user.longitude)
            let destloc = CLLocation(latitude: dest.latitude, longitude: dest.longitude)
            return MeasureUtil.distance(from: userloc, to: destloc)
        }
        return nil
    }

    @Published var routes: Route.Result? {
        didSet {
            showRoutes()
        }
    }
    @Published var showingRoutes = false {
        didSet {
            if showingRoutes {
                fetchRoutes(byForce: true)
            } else {
                showRoutes() // Hide routes
            }
        }
    }

    @Published var address: [String?]?
    @Published var showsAddress = false {
        didSet {
            if showsAddress {
                fetchAddress()
            }
        }
    }

    private var cancellable: AnyCancellable?
    private var subcancellables = Set<AnyCancellable>()

    init() {
        cancellable = DestinationSet.currentPublisher.sink { [self] current in
            subcancellables.removeAll()

            current.destinationsPublisher.sink { [self] in
                objectWillChange.send()

                syncDestinations()

                if $0.isEmpty {
                    originOnly = true
                    showingRoutes = false
                }
            }
            .store(in: &subcancellables)

            current.targetIndexPublisher.sink { [self] _ in
                objectWillChange.send()

                if !originOnly && following {
                    setRegionWithDestination()
                }

                refreshAnnotations()
                addTargetLine()
                fetchRoutes(byForce: true)
            }
            .store(in: &subcancellables)
        }
    }

    /// Sync the annotations in the map view with the destinations.
    func syncDestinations() {
        if let mapView = mapView {
            DestinationSet.current.destinations.forEach { dest in
                if !mapView.annotations.contains(where: { ($0 as? Destination) == dest }) {
                    mapView.addAnnotation(dest)
                }
            }

            mapView.annotations.reversed().forEach { ann in
                if let ann = ann as? Destination,
                   !DestinationSet.current.destinations.contains(where: { $0 == ann }) {
                    mapView.removeAnnotation(ann)
                }
            }
        }
    }

    func setCenter(_ coordinate: CLLocationCoordinate2D, animated: Bool = false) {
        // It is difficult for mapView(regionDidChangeAnimated:) to tell
        // scrolling by setCenter() here from scrolling on
        // mapView(didUpdate: MKUserLocation). The former should turn
        // off following but the latter shouldn't, so here turn off
        // following manually.
        if !originOnly && following {
            following = false
        }

        mapView?.setCenter(coordinate, animated: animated)
    }

    func setRegionWithDestination(animated: Bool = true) {
        if let mapView = mapView, let target = DestinationSet.current.target {
            mapView.setRegion(
                MKCoordinateRegion.contains(
                    [mapView.userLocation.coordinate,
                     target.coordinate]),
                animated: animated)
        }
    }

    /// Draw a line from the user location to the target.
    func addTargetLine() {
        if let mapView = mapView {
            DispatchQueue.main.async { [self] in
                mapView.removeOverlays(mapView.overlays.filter { !($0 is Route.Polyline) })
                if let target = DestinationSet.current.target {
                    let user = mapView.userLocation
                    if !visible(target.coordinate, in: mapView) ||
                        !visible(user.coordinate, in: mapView) {
                        let coords = [user.coordinate, target.coordinate]
                        let overlay = MKPolyline(coordinates: coords, count: coords.count)
                        mapView.addOverlay(overlay, level: .aboveRoads)
                    }
                }
            }
        }
    }

    /// Returns whether the coordinate can currently be seen in the map view.
    func visible(_ coordinate: CLLocationCoordinate2D, in mapView: MKMapView) -> Bool {
        let cgpoint = mapView.convert(coordinate, toPointTo: mapView)
        return mapView.frame.contains(cgpoint)
    }

    func refreshAnnotations() {
        if let mapView = mapView {
            let anns = mapView.annotations.filter {
                $0 is Destination && mapView.view(for: $0) != nil
            }
            mapView.removeAnnotations(anns)
            mapView.addAnnotations(anns)
        }
    }

    func setupAnnotationView(_ view: MKAnnotationView) {
        if let view = view as? MKMarkerAnnotationView,
           let annotation = view.annotation as? Destination {
            let isTarget = annotation == DestinationSet.current.target
            view.markerTintColor = isTarget ? .systemPurple : nil
            view.displayPriority = isTarget ? .required : .defaultHigh
            if let index = DestinationSet.current.destinations.firstIndex(of: annotation) {
                view.glyphText = String(index + 1)
            }
        }
    }

    /// Fetch routes.
    /// - Parameter byForce: If true, go anyway. Wait until the attempt can be made, if needed.
    func fetchRoutes(byForce: Bool = false) {
        Task { @MainActor in
            if showingRoutes, let mapView = mapView,
                let userloc = mapView.userLocation.location,
                let target = DestinationSet.current.target {
                if byForce {
                    routes = nil
                }

                let targetloc = CLLocation(latitude: target.coordinate.latitude, longitude: target.coordinate.longitude)
                if !byForce && !Route.canFetch(from: userloc, to: targetloc, before: routes) {
                    return
                }

                do {
                    let result = try await Route.fetch(from: userloc, to: targetloc, byForce: byForce)
                    if DestinationSet.current.target == target {
                        routes = result
                    }
                } catch {
                    // Ignore an error.
                }
            }
        }
    }

    func showRoutes() {
        if let mapView = mapView {
            mapView.removeOverlays(mapView.overlays.filter { $0 is Route.Polyline })

            if showingRoutes, let routes = routes {
                mapView.addOverlays(routes.routes, level: .aboveRoads)
            }
        }
    }

    func fetchAddress() {
        if let mapView = mapView, let userloc = mapView.userLocation.location {
            if !Address.canFetch(location: userloc) {
                return
            }

            Address.fetch(location: userloc) { [self] result, error in
                if error != nil {
                    // Ignore an error.
                } else if let result = result {
                    address = result.address
                }
            }
        }
    }
}
