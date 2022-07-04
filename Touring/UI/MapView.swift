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
        context.coordinator.drawScopes(uiView)
    }

    func makeCoordinator() -> MapViewCoordinator {
        MapViewCoordinator(self)
    }
}

class MapViewCoordinator: NSObject {
    private let view: MapView

    private var userScopeImage: UIImageView?
    private var targetScopeImage: UIImageView?

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
        view.map.addTargetLine()
        drawScopes(mapView)

        if view.map.heading != mapView.camera.heading {
            view.map.heading = mapView.camera.heading

            if !view.map.originOnly && view.map.following {
                DispatchQueue.main.async { [self] in
                    view.map.setRegionWithDestination(animated: true)
                }
            }
        }
    }

    private func createScopeImage(color: UIColor) -> UIImageView? {
        if let scopeImage = UIImage(
            systemName: "scope",
            withConfiguration: UIImage.SymbolConfiguration(weight: .ultraLight))?
            .withTintColor(color, renderingMode: .alwaysOriginal) {
            let imageView = UIImageView(image: scopeImage)
            imageView.frame.size = CGSize(width: 150, height: 150)
            imageView.isHidden = true
            return imageView
        } else {
            return nil
        }
    }

    private func drawScope(_ mapView: MKMapView, image: UIImageView, at coordinate: CLLocationCoordinate2D?) {
        image.isHidden = true
        if let coordinate = coordinate, let window = UIApplication.shared.keyWindow {
            let cgpoint = mapView.convert(coordinate, toPointTo: nil)
            if window.frame.contains(cgpoint) {
                image.center = cgpoint
                image.isHidden = mapView.upperViews.filter {
                    // Ignore large views, as they are probably dialogs.
                    $0.frame.height < window.frame.height / 2 &&
                    $0.frame.contains(cgpoint)
                }.isEmpty
            }
        }
    }

    func drawScopes(_ mapView: MKMapView) {
        if userScopeImage == nil {
            userScopeImage = createScopeImage(color: .systemBlue)
            userScopeImage.map { mapView.addSubview($0) }
        }
        if let userScopeImage = userScopeImage {
            drawScope(mapView, image: userScopeImage, at: mapView.userLocation.location?.coordinate)
        }

        if let target = DestinationSet.current.target {
            if targetScopeImage == nil {
                targetScopeImage = createScopeImage(color: .systemPurple)
                targetScopeImage.map { mapView.addSubview($0) }
            }
            if let targetScopeImage = targetScopeImage {
                drawScope(mapView, image: targetScopeImage, at: target.coordinate)
            }
        }
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let ann = view.annotation as? Destination,
            let index = DestinationSet.current.destinations.firstIndex(of: ann) {
            if !self.view.map.movingDestination {
                self.view.map.selectedDestination = index
            }
            mapView.deselectAnnotation(ann, animated: false)
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

        drawScopes(mapView)
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
           mapView.selectedAnnotations.isEmpty && !view.map.movingDestination {
            let cgpoint = sender.location(in: mapView)

            if mapView.tappedAnnotations(at: cgpoint).isEmpty {
                let coord = mapView.convert(cgpoint, toCoordinateFrom: mapView)

                let dest = Destination()
                dest.coordinate = coord
                DestinationSet.current.destinations += [dest]
                try? DestinationSet.saveAll()

                mapView.selectAnnotation(dest, animated: true)
            }
        }
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}
