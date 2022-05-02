import MapKit
import SwiftUI

/// The information of a map view that the parent view may want.
struct MapViewContext {
    var heading: CLLocationDirection = 0
    var destinations: [MKPointAnnotation] = []
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

        let recog = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.longPressed(_:)))
        recog.delegate = context.coordinator
        view.addGestureRecognizer(recog)

        // mapViewContext.destinations seems not to be updated immediately here.
        DispatchQueue.main.async {
            try? mapViewContext.destinations = MapUtil.loadDestinations()
            view.addAnnotations(mapViewContext.destinations)
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
}

extension MapViewCoordinator: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        view.mapViewContext.heading = mapView.camera.heading
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
        if let mapView = sender.view as? MKMapView, sender.state == .began {
            let cgpoint = sender.location(in: mapView)
            let coord = mapView.convert(cgpoint, toCoordinateFrom: mapView)
            let ann = MKPointAnnotation()
            ann.coordinate = coord
            view.mapViewContext.destinations += [ann]
            try? MapUtil.saveDestinations(view.mapViewContext.destinations)
            mapView.addAnnotation(ann)
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
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView(mapViewContext: .constant(MapViewContext()))
    }
}
