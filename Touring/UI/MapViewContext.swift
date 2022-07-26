import Combine
import MapKit

/// The information of a map view that the parent view may want.
class MapViewContext: ObservableObject {
    weak var mapView: MKMapView?

    @Published var heading: CLLocationDirection = 0

    @Published var selectedDestination: Int = -1

    private func refreshOnMapMode() {
        if refreshingOnMapMode, let mapView = mapView {
            mapView.setUserTrackingMode(mapMode == .origin && following ? .follow : .none, animated: true)

            if mapMode != .origin && following {
                setRegionWithDestination()
            }
        }
    }
    /// Whether refresh the map when the map mode has been changed.
    @Published var refreshingOnMapMode = true {
        didSet {
            refreshOnMapMode()
        }
    }
    @Published var following = false {
        didSet {
            refreshOnMapMode()
        }
    }
    @Published var originOnly = true {
        didSet {
            refreshOnMapMode()
        }
    }
    @Published var overall = false {
        didSet {
            refreshOnMapMode()
        }
    }

    enum MapMode {
        case origin, target, overall
    }
    var mapMode: MapMode {
        overall ? .overall : originOnly ? .origin : .target
    }

    @Published var routes: Route.Result? {
        didSet {
            showRoutes()
        }
    }
    @Published var travelType: Location.TravelType = .automobile {
        didSet {
            if travelType != oldValue && showingRoutes {
                fetchRoutes(byForce: true)
            }
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
                    overall = false
                    showingRoutes = false
                } else {
                    refreshAnnotations()
                }
            }
            .store(in: &subcancellables)

            current.targetIndexPublisher.sink { [self] _ in
                objectWillChange.send()

                if mapMode != .origin && following {
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
        if mapMode != .origin && following {
            following = false
        }

        mapView?.setCenter(coordinate, animated: animated)
    }

    func setRegionWithDestination(animated: Bool = true) {
        if let mapView = mapView, let target = DestinationSet.current.target, let user = mapView.userLocation.location {
            // We'll use MKMapView#setCamera(). MKMapView#setRegion()
            // and MKMapView#showAnnotations() don't keep the map
            // orientation, MKMapView#camera.heading, but
            // MKMapView#setCamera() does.

            let padding = 0.15

            // Minimum camera coverage, in meters.
            let mincov = 100.0
            let mincamdist = (mincov / 2) / tan(15.0 * .pi / 180)

            let coords = [user.coordinate] +
                (overall ? DestinationSet.current.destinations.map { $0.coordinate } : [target.coordinate])

            // Temporarily convert the coordinates to CGPoint, since
            // MKMapView#convert(_:toPointTo:) considers the map
            // orientation.
            var rect = CGRect.null
            for coord in coords {
                let point = mapView.convert(coord, toPointTo: mapView)
                rect = rect.union(CGRect(x: point.x, y: point.y, width: 0, height: 0))
            }

            let center = mapView.convert(CGPoint(x: rect.midX, y: rect.midY), toCoordinateFrom: mapView)

            let width = rect.width * (1.0 + padding * 2)
            let height = rect.height * (1.0 + padding * 2)
            let xzoom = width / mapView.bounds.width
            let yzoom = height / mapView.bounds.height
            let camdist = max(mincamdist, mapView.camera.centerCoordinateDistance * max(xzoom, yzoom))

            let camera = MKMapCamera(
                lookingAtCenter: center, fromDistance: camdist,
                pitch: mapView.camera.pitch, heading: mapView.camera.heading)
            mapView.setCamera(camera, animated: animated)
        }
    }

    /// Draw a line from the user location to the target.
    func addTargetLine() {
        if let mapView = mapView {
            DispatchQueue.main.async { [self] in
                mapView.removeOverlays(mapView.overlays.filter { !($0 is Route.Polyline) })
                if let user = mapView.userLocation.location,
                    let target = DestinationSet.current.target,
                    !visible(target.coordinate, in: mapView) ||
                    !visible(user.coordinate, in: mapView) {
                    let coords = [user.coordinate, target.coordinate]
                    let overlay = MKPolyline(coordinates: coords, count: coords.count)
                    mapView.addOverlay(overlay, level: .aboveRoads)
                }
            }
        }
    }

    /// Returns whether the coordinate can currently be seen in the map view.
    func visible(_ coordinate: CLLocationCoordinate2D, in mapView: MKMapView) -> Bool {
        let cgpoint = mapView.convert(coordinate, toPointTo: mapView)
        return mapView.bounds.contains(cgpoint)
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
                    let result = try await Route.fetch(from: userloc, to: targetloc, by: travelType, byForce: byForce)
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

    // MARK: - Moving a Destination
    private var movingDestinationIndex: Int?
    private var savedFollowing: Bool?
    private var savedCamera: MKMapCamera?
    private var movingFinderImage: UIImageView?

    var movingDestination: Bool {
        movingDestinationIndex != nil
    }

    func startMovingDestination(at index: Int) {
        if !movingDestination {
            movingDestinationIndex = index
            savedFollowing = following
            savedCamera = mapView?.camera.copy() as? MKMapCamera
        }
        if let mapView = mapView {
            let region = MKCoordinateRegion(
                center: DestinationSet.current.destinations[index].coordinate,
                latitudinalMeters: 30, longitudinalMeters: 30)
            mapView.setRegion(region, animated: false)
        }

        drawMovingFinder()
    }

    func moveDestination(to coord: CLLocationCoordinate2D? = nil) {
        if let index = movingDestinationIndex, let coord = (coord ?? mapView?.region.center) {
            DestinationSet.current.destinations[index].coordinate = coord
        }
    }

    func endMovingDestination() {
        if let savedFollowing = savedFollowing {
            following = savedFollowing
            self.savedFollowing = nil
        }
        if let savedCamera = savedCamera {
            mapView?.camera = savedCamera
            self.savedCamera = nil
        }
        movingDestinationIndex = nil
        mapView?.mapType = .standard

        movingFinderImage.map { $0.removeFromSuperview() }
        movingFinderImage = nil

        fetchRoutes(byForce: true)
    }

    private func drawMovingFinder() {
        if let mapView = mapView {
            if movingFinderImage == nil {
                let size = 50
                let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
                let img = renderer.image { ctx in
                    // It would be unnecessary to respond to changes of
                    // the light/dark appearance, since the color
                    // mismatch will last only during moving a
                    // destination.
                    ctx.cgContext.setStrokeColor(UIColor.systemBackground.cgColor)
                    ctx.cgContext.setLineWidth(3)
                    ctx.cgContext.strokeLineSegments(between: [
                        CGPoint(x: 0, y: size / 2), CGPoint(x: size - 1, y: size / 2),
                        CGPoint(x: size / 2, y: 0), CGPoint(x: size / 2, y: size - 1)
                    ])

                    ctx.cgContext.setStrokeColor(UIColor.label.cgColor)
                    ctx.cgContext.setLineWidth(1)
                    ctx.cgContext.strokeLineSegments(between: [
                        CGPoint(x: 1, y: size / 2), CGPoint(x: size - 2, y: size / 2),
                        CGPoint(x: size / 2, y: 1), CGPoint(x: size / 2, y: size - 2)
                    ])
                }
                let imageView = UIImageView(image: img)
                imageView.center = mapView.center
                movingFinderImage = imageView
            }
            movingFinderImage.map { mapView.addSubview($0) }
        }
    }
}
