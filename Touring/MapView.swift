import MapKit
import SwiftUI

/// The information of a map view that the parent view may want.
struct MapViewContext {
    fileprivate weak var mapView: MKMapView?

    var heading: CLLocationDirection = 0
    var destinations: [MKPointAnnotation] = [] {
        didSet {
            let oldSelectedDestination = currentDestination.map { oldValue[$0] }

            syncDestinations()

            if destinations.isEmpty {
                originOnly = true
            } else if currentDestination == nil {
                currentDestination = destinations.startIndex
            }

            // If the previously selected destination still exists, it
            // should be kept selected.
            if let oldSelectedDestination = oldSelectedDestination,
                let index = destinations.firstIndex(of: oldSelectedDestination) {
                currentDestination = index
            } else if currentDestination.map({ $0 >= destinations.endIndex }) ?? false {
                currentDestination = destinations.endIndex - 1
            }

            refreshAnnotations()

            if !originOnly && following && oldSelectedDestination != currentDestination.map({ destinations[$0] }) {
                setRegionWithDestination()
            }
        }
    }

    var selectedDestination: Int = -1

    var currentDestination: Int? {
        didSet {
            if destinations.isEmpty {
                currentDestination = nil
            } else if let dest = currentDestination {
                if dest < destinations.startIndex {
                    currentDestination = destinations.startIndex
                } else if dest >= destinations.endIndex {
                    currentDestination = destinations.endIndex - 1
                }
            }

            refreshAnnotations()
            addDestinationLine()
        }
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

    var currentDestinationDistance: CLLocationDistance? {
        if let mapView = mapView, let currentDestination = currentDestination {
            let user = mapView.userLocation.coordinate
            let dest = destinations[currentDestination].coordinate
            let userloc = CLLocation(latitude: user.latitude, longitude: user.longitude)
            let destloc = CLLocation(latitude: dest.latitude, longitude: dest.longitude)
            return MeasureUtil.distance(from: userloc, to: destloc)
        }
        return nil
    }

    mutating func goForward() {
        if let dest = currentDestination {
            if dest + 1 >= destinations.endIndex {
                currentDestination = destinations.startIndex
            } else {
                currentDestination = dest + 1
            }
        }

        if !originOnly && following {
            setRegionWithDestination()
        }
    }

    mutating func goBackward() {
        if let dest = currentDestination {
            if dest - 1 < destinations.startIndex {
                currentDestination = destinations.endIndex - 1
            } else {
                currentDestination = dest - 1
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
        if let mapView = mapView, let currentDestination = currentDestination,
           currentDestination < destinations.endIndex {
            mapView.setRegion(
                MapUtil.region(
                    with: [mapView.userLocation.coordinate,
                           destinations[currentDestination].coordinate]),
                animated: animated)
        }
    }

    /// Draw a line from the user location to the destination.
    func addDestinationLine() {
        if let mapView = mapView, let destIndex = currentDestination {
            DispatchQueue.main.async {
                mapView.removeOverlays(mapView.overlays)
                let dest = destinations[destIndex]
                let user = mapView.userLocation
                if !visible(dest.coordinate, in: mapView) ||
                    !visible(user.coordinate, in: mapView) {
                    let coords = [user.coordinate, dest.coordinate]
                    let overlay = MKPolyline(coordinates: coords, count: coords.count)
                    mapView.addOverlay(overlay, level: .aboveRoads)
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
            let isCurrent = annotation == currentDestination.map { destinations[$0] }
            view.markerTintColor = isCurrent ? .systemPurple : nil
            view.displayPriority = isCurrent ? .required : .defaultHigh
            if let index = destinations.firstIndex(of: annotation) {
                view.glyphText = String(index + 1)
            }
        }
    }
}

struct MapView: UIViewRepresentable {
    @Binding var mapViewContext: MapViewContext

    func makeUIView(context: Context) -> MKMapView {
        // Giving a non-empty frame is a workaround for the strange
        // behavior that .userTrackingMode is reset to .none during
        // initialization.
        let view = MKMapView(frame: UIScreen.main.bounds)
        view.delegate = context.coordinator
        view.userTrackingMode = .follow
        view.showsScale = true
        view.showsTraffic = true

        mapViewContext.mapView = view

        let recog = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.longPressed(_:)))
        recog.delegate = context.coordinator
        view.addGestureRecognizer(recog)

        // mapViewContext.destinations seems not to be updated immediately here.
        DispatchQueue.main.async {
            try? mapViewContext.destinations = MapUtil.loadDestinations()
        }

        return view
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
    }

    func makeCoordinator() -> MapViewCoordinator {
        MapViewCoordinator(self)
    }
}

class MapViewCoordinator: NSObject {
    private let view: MapView

    init(_ view: MapView) {
        self.view = view
    }

    /// Returns whether the map view is being gestured.
    private func gestured(_ mapView: MKMapView) -> Bool {
        if let recogs = mapView.subviews.first?.gestureRecognizers {
            for recog in recogs {
                if recog.state == .began || recog.state == .ended || recog.state == .changed {
                    return true
                }
            }
        }
        return false
    }
}

extension MapViewCoordinator: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        view.mapViewContext.heading = mapView.camera.heading

        view.mapViewContext.addDestinationLine()
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let ann = view.annotation as? MKPointAnnotation,
           let index = self.view.mapViewContext.destinations.firstIndex(of: ann) {
            self.view.mapViewContext.selectedDestination = index

            // Wait for long-press gesture deadline and deselect the
            // annotation.
            //
            // * The reason for deselecting is: if the annotation is
            //   left selected, tapping it won't open its detail sheet
            //   until it is deselected.
            //
            // * The reason for waiting is: if the annotation is
            //   deselected immediately, and the user long-presses it,
            //   then not only will its detail sheet be opened but
            //   also another annotation will be created.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak ann] in
                if let ann = ann {
                    mapView.deselectAnnotation(ann, animated: false)
                }
            }
        }
    }

    func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
        // Without DispatchQueue.main.async, during initialization,
        // the modification here of `following` seems not to be
        // reflected immediately.
        DispatchQueue.main.async {
            if self.view.mapViewContext.originOnly {
                self.view.mapViewContext.following = (mode != .none)
            }
        }
    }

    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if !view.mapViewContext.originOnly && view.mapViewContext.following {
            view.mapViewContext.setRegionWithDestination(animated: false)
        }
    }

    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        if !view.mapViewContext.originOnly && gestured(mapView) {
            view.mapViewContext.following = false
        }
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: overlay)
            renderer.strokeColor = .systemCyan
            renderer.lineWidth = 3
            renderer.lineDashPattern = [0, 10]
            return renderer
        } else {
            return MKOverlayRenderer(overlay: overlay)
        }
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? MKPointAnnotation else { return nil }

        let reuseId = "destination"
        let av = { () -> MKMarkerAnnotationView in
            if let av = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKMarkerAnnotationView {
                av.annotation = annotation
                return av
            } else {
                return MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            }
        }()

        view.mapViewContext.setupAnnotationView(av)
        return av
    }
}

extension MapViewCoordinator: UIGestureRecognizerDelegate {
    // MKMapView has some UIGestureRecognizers in itself, and they also
    // should be allowed to recognize gestures simultaneously.
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }

    @IBAction func longPressed(_ sender: UIGestureRecognizer) {
        if let mapView = sender.view as? MKMapView, sender.state == .began,
           mapView.selectedAnnotations.isEmpty {
            let cgpoint = sender.location(in: mapView)
            let coord = mapView.convert(cgpoint, toCoordinateFrom: mapView)
            let ann = MKPointAnnotation()
            ann.coordinate = coord
            view.mapViewContext.destinations += [ann]
            try? MapUtil.saveDestinations(view.mapViewContext.destinations)
        }
    }
}

extension MapView {
    enum Error: Swift.Error {
        case fileIOError(original: Swift.Error?)
        case jsonCodingError
    }
}

enum MapUtil {
    static func destinationFileUrl() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first!.appendingPathComponent("destinations.json")
    }

    static func saveDestinations(_ destinations: [MKPointAnnotation]) throws {
        let dests = destinations.map {
            SavedDestination(title: $0.title,
                             latitude: $0.coordinate.latitude,
                             longitude: $0.coordinate.longitude)
        }

        guard let json = try? JSONEncoder().encode(dests) else {
            throw MapView.Error.jsonCodingError
        }

        if !FileManager.default.createFile(atPath: destinationFileUrl().path, contents: json) {
            throw MapView.Error.fileIOError(original: nil)
        }
    }

    static func loadDestinations() throws -> [MKPointAnnotation] {
        guard let json = FileManager.default.contents(atPath: destinationFileUrl().path) else {
            return []
        }

        guard let dests = try? JSONDecoder().decode([SavedDestination].self, from: json) else {
            throw MapView.Error.jsonCodingError
        }

        let asdf: [MKPointAnnotation] = dests.map {
            let ann = MKPointAnnotation()
            ann.title = $0.title
            ann.coordinate.latitude = $0.latitude
            ann.coordinate.longitude = $0.longitude
            return ann
        }
        return asdf
    }

    struct SavedDestination: Codable {
        var title: String?
        var latitude: Double
        var longitude: Double
    }

    /// Returns a region that contains all the coordinates.
    static func region(with coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        let paddingratio = 0.15
        let deltamin: CLLocationDegrees = 0.001
        var rect = MKMapRect.null
        for coord in coordinates {
            rect = rect.union(MKMapRect(origin: MKMapPoint(coord), size: MKMapSize()))
        }
        var region = MKCoordinateRegion(rect.insetBy(dx: rect.width * -paddingratio, dy: rect.height * -paddingratio))
        if region.span.latitudeDelta < deltamin {
            region.span.latitudeDelta = deltamin
        }
        if region.span.longitudeDelta < deltamin {
            region.span.longitudeDelta = deltamin
        }
        return region
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView(mapViewContext: .constant(MapViewContext()))
    }
}
