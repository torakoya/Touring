import MapKit
import SwiftUI

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
            try? mapViewContext.destinations = Destination.load()
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
    let view: MapView

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

        view.mapViewContext.addTargetLine()
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let ann = view.annotation as? Destination,
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

        if !view.mapViewContext.following {
            view.mapViewContext.addTargetLine()
        }

        if view.mapViewContext.showingRoutes {
            view.mapViewContext.fetchRoutes()
        }

        if view.mapViewContext.showsAddress {
            view.mapViewContext.fetchAddress()
        }
    }

    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        if !view.mapViewContext.originOnly && gestured(mapView) {
            view.mapViewContext.following = false
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

        DispatchQueue.main.async { [self] in
            view.mapViewContext.setupAnnotationView(av)
        }
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
            view.mapViewContext.destinations += [dest]
            try? Destination.save(view.mapViewContext.destinations)
        }
    }
}

extension MapView {
    enum Error: Swift.Error {
        case fileIOError(original: Swift.Error?)
        case jsonCodingError
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView(mapViewContext: .constant(MapViewContext()))
    }
}
