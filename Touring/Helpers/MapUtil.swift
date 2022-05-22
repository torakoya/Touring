import MapKit

enum MapUtil {
    static func destinationFileUrl() -> URL {
        FileManager.default.documentURL(of: "destinations.json")
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
