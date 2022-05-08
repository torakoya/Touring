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
                currentDestination = nil
                originOnly = true
            } else if currentDestination == nil {
                currentDestination = destinations.startIndex
            } else if currentDestination! >= destinations.endIndex {
                currentDestination = destinations.endIndex - 1
            }

            // If the previously selected destination still exists, it
            // should be kept selected.
            if let oldSelectedDestination = oldSelectedDestination {
                currentDestination = destinations.firstIndex(of: oldSelectedDestination)
 ?? currentDestination
            }

            if !originOnly && following && oldSelectedDestination != currentDestination.map({ destinations[$0] }) {
                setRegionWithDestination()
            }
        }
    }

    var selectedDestination: Int = -1

    var currentDestination: Int?
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

    mutating func goForward() {
        if destinations.isEmpty {
            currentDestination = nil
        } else if currentDestination == nil {
            currentDestination = destinations.startIndex
        } else {
            currentDestination! += 1
            if currentDestination! >= destinations.endIndex {
                currentDestination = destinations.startIndex
            }
        }

        if !originOnly && following {
            setRegionWithDestination()
        }
    }

    mutating func goBackward() {
        if destinations.isEmpty {
            currentDestination = nil
        } else if currentDestination == nil {
            currentDestination = destinations.endIndex - 1
        } else {
            currentDestination! -= 1
            if currentDestination! < destinations.startIndex {
                currentDestination = destinations.endIndex - 1
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
