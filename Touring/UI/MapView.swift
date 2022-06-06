import MapKit
import SwiftUI

struct MapView: UIViewRepresentable {
    @EnvironmentObject fileprivate var map: MapViewContext

    func makeUIView(context: Context) -> MKMapView {
        // Giving a non-empty frame is a workaround for the strange
        // behavior that .userTrackingMode is reset to .none during
        // initialization.
        let view = MKMapView(frame: UIScreen.main.bounds)
        view.delegate = context.coordinator
        view.userTrackingMode = .follow
        view.showsScale = true
        view.showsTraffic = true

        map.mapView = view

        let recog = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.longPressed(_:)))
        recog.delegate = context.coordinator
        view.addGestureRecognizer(recog)

        try? DestinationSet.loadAll()

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
        view.map.heading = mapView.camera.heading

        view.map.addTargetLine()
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let ann = view.annotation as? Destination,
            let index = DestinationSet.current.destinations.firstIndex(of: ann) {
            self.view.map.selectedDestination = index

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
        if self.view.map.originOnly {
            self.view.map.following = (mode != .none)
        }
    }

    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if !view.map.originOnly && view.map.following {
            view.map.setRegionWithDestination(animated: false)
        }

        if !view.map.following {
            view.map.addTargetLine()
        }

        if view.map.showingRoutes {
            view.map.fetchRoutes()
        }

        if view.map.showsAddress {
            view.map.fetchAddress()
        }
    }

    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        if !view.map.originOnly && gestured(mapView) {
            view.map.following = false
        }
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? Route.Polyline {
            let renderer = MKPolylineRenderer(polyline: overlay)
            renderer.strokeColor = overlay.advisoryNotices.isEmpty ? .systemBlue : .systemRed
            if overlay.isFirst {
                renderer.lineWidth = 3.5
            } else {
                renderer.lineWidth = 2.5
                renderer.lineDashPattern = [5, 7, 0, 7]
            }
            return renderer
        } else if let overlay = overlay as? MKPolyline {
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
        guard let annotation = annotation as? Destination else { return nil }

        let reuseId = "destination"
        let av = { () -> MKMarkerAnnotationView in
            if let av = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKMarkerAnnotationView {
                av.annotation = annotation
                return av
            } else {
                return MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            }
        }()

        view.map.setupAnnotationView(av)
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
            let dest = Destination()
            dest.coordinate = coord
            DestinationSet.current.destinations += [dest]
            try? DestinationSet.saveAll()
        }
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}
