import Foundation
import MapKit

class Destination: MKPointAnnotation {
    static var destinationFileUrl: URL {
        FileManager.default.documentURL(of: "destinations.json")
    }

    static func save(_ destinations: [Destination]) throws {
        let dests = destinations.map {
            SavedDestination(title: $0.title,
                             latitude: $0.coordinate.latitude,
                             longitude: $0.coordinate.longitude)
        }

        guard let json = try? JSONEncoder().encode(dests) else {
            throw MapView.Error.jsonCodingError
        }

        if !FileManager.default.createFile(atPath: destinationFileUrl.path, contents: json) {
            throw MapView.Error.fileIOError(original: nil)
        }
    }

    static func load() throws -> [Destination] {
        guard let json = FileManager.default.contents(atPath: destinationFileUrl.path) else {
            return []
        }

        guard let dests = try? JSONDecoder().decode([SavedDestination].self, from: json) else {
            throw MapView.Error.jsonCodingError
        }

        return dests.map {
            let dest = Destination()
            dest.title = $0.title
            dest.coordinate.latitude = $0.latitude
            dest.coordinate.longitude = $0.longitude
            return dest
        }
    }

    struct SavedDestination: Codable {
        var title: String?
        var latitude: Double
        var longitude: Double
    }
}
