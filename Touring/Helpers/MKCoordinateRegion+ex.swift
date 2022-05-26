import MapKit

extension MKCoordinateRegion {
    /// Returns a region that contains all the coordinates.
    static func contains(_ coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
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
