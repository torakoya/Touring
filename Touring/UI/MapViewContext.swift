import MapKit

/// The information of a map view that the parent view may want.
struct MapViewContext {
    weak var mapView: MKMapView?

    var heading: CLLocationDirection = 0
    var destinations: [MKPointAnnotation] = [] {
        didSet {
            let oldTarget = targetIndex.map { oldValue[$0] }
            let oldTargetIndex = targetIndex

            syncDestinations()

            if destinations.isEmpty {
                originOnly = true
            } else if targetIndex == nil {
                targetIndex = destinations.startIndex
            }

            // If the previously aimed-at target still exists, it
            // should be kept aimed at.
            if let oldTarget = oldTarget,
                let index = destinations.firstIndex(of: oldTarget) {
                targetIndex = index
            } else if targetIndex.map({ $0 >= destinations.endIndex }) ?? false {
                targetIndex = destinations.endIndex - 1
            }

            refreshAnnotations()

            // If targetIndex hasn't been unchanged but target has
            // been changed by removing a destination, the line should
            // be redrawn.
            if let target = target, targetIndex == oldTargetIndex && target != oldTarget {
                addTargetLine()
                fetchRoutes(byForce: true)
            }

            if !originOnly && following && oldTarget != target {
                setRegionWithDestination()
            }
        }
    }

    var selectedDestination: Int = -1

    var targetIndex: Int? {
        didSet {
            if destinations.isEmpty {
                targetIndex = nil
            } else if let dest = targetIndex {
                if dest < destinations.startIndex {
                    targetIndex = destinations.startIndex
                } else if dest >= destinations.endIndex {
                    targetIndex = destinations.endIndex - 1
                }
            }

            refreshAnnotations()
            addTargetLine()
            fetchRoutes(byForce: true)
        }
    }

    /// The destination currently headed for.
    var target: MKPointAnnotation? {
        targetIndex.map { $0 >= destinations.startIndex && $0 < destinations.endIndex ? destinations[$0] : nil } ?? nil
    }

    var following = false {
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
    var originOnly = true {
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
        if let mapView = mapView, let target = target {
            let user = mapView.userLocation.coordinate
            let dest = target.coordinate
            let userloc = CLLocation(latitude: user.latitude, longitude: user.longitude)
            let destloc = CLLocation(latitude: dest.latitude, longitude: dest.longitude)
            return MeasureUtil.distance(from: userloc, to: destloc)
        }
        return nil
    }

    var routes: Route.Result? {
        didSet {
            showRoutes()
        }
    }
    var showingRoutes = false {
        didSet {
            if showingRoutes {
                fetchRoutes(byForce: true)
            } else {
                showRoutes() // Hide routes
            }
        }
    }

    var address: [String?]?
    var showsAddress = false {
        didSet {
            if showsAddress {
                fetchAddress()
            }
        }
    }

    mutating func goForward() {
        if let dest = targetIndex {
            if dest + 1 >= destinations.endIndex {
                targetIndex = destinations.startIndex
            } else {
                targetIndex = dest + 1
            }
        }

        if !originOnly && following {
            setRegionWithDestination()
        }
    }

    mutating func goBackward() {
        if let dest = targetIndex {
            if dest - 1 < destinations.startIndex {
                targetIndex = destinations.endIndex - 1
            } else {
                targetIndex = dest - 1
            }
        }

        if !originOnly && following {
            setRegionWithDestination()
        }
    }

    /// Sync the annotations in the map view with the destinations.
    func syncDestinations() {
        if let mapView = mapView {
            destinations.forEach { dest in
                if !mapView.annotations.contains(where: { ($0 as? MKPointAnnotation) == dest }) {
                    mapView.addAnnotation(dest)
                }
            }

            mapView.annotations.reversed().forEach { ann in
                if let ann = ann as? MKPointAnnotation,
                    !destinations.contains(where: { $0 == ann }) {
                    mapView.removeAnnotation(ann)
                }
            }
        }
    }

    func setRegionWithDestination(animated: Bool = true) {
        if let mapView = mapView, let target = target {
            mapView.setRegion(
                MapUtil.region(
                    with: [mapView.userLocation.coordinate,
                           target.coordinate]),
                animated: animated)
        }
    }

    /// Draw a line from the user location to the target.
    func addTargetLine() {
        if let mapView = mapView {
            DispatchQueue.main.async {
                mapView.removeOverlays(mapView.overlays.filter { !($0 is Route.Polyline) })
                if let target = target {
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
            for annotation in mapView.annotations {
                if let view = mapView.view(for: annotation) {
                    setupAnnotationView(view)
                }
            }
        }
    }

    func setupAnnotationView(_ view: MKAnnotationView) {
        if let view = view as? MKMarkerAnnotationView,
           let annotation = view.annotation as? MKPointAnnotation {
            let isTarget = annotation == target
            view.markerTintColor = isTarget ? .systemPurple : nil
            view.displayPriority = isTarget ? .required : .defaultHigh
            if let index = destinations.firstIndex(of: annotation) {
                view.glyphText = String(index + 1)
            }
        }
    }

    /// Fetch routes.
    /// - Parameter byForce: If true, go anyway. Wait until the attempt can be made, if needed.
    func fetchRoutes(byForce: Bool = false) {
        Task { @MainActor in
            if showingRoutes, let mapView = mapView, let userloc = mapView.userLocation.location, let target = target {
                if byForce, let view = (mapView.delegate as? MapViewCoordinator)?.view {
                    view.mapViewContext.routes = nil
                }

                let targetloc = CLLocation(latitude: target.coordinate.latitude, longitude: target.coordinate.longitude)
                if !byForce && !Route.canFetch(from: userloc, to: targetloc, before: routes) {
                    return
                }

                do {
                    let result = try await Route.fetch(from: userloc, to: targetloc, byForce: byForce)
                    if let view = (mapView.delegate as? MapViewCoordinator)?.view,
                        view.mapViewContext.target == target {
                        view.mapViewContext.routes = result
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

            Address.fetch(location: userloc) { result, error in
                if error != nil {
                    // Ignore an error.
                } else if let result = result, let view = (mapView.delegate as? MapViewCoordinator)?.view {
                    view.mapViewContext.address = result.address
                }
            }
        }
    }
}
