import Foundation
import MapKit

final class Destination: MKPointAnnotation {
}

extension Destination: Codable {
    enum CodingKeys: String, CodingKey {
        case title
        case latitude
        case longitude
    }

    convenience init(from decoder: Decoder) throws {
        self.init()

        let values = try decoder.container(keyedBy: CodingKeys.self)
        if values.contains(.title) {
            title = try values.decode(String.self, forKey: .title)
        }
        coordinate.latitude = try values.decode(CLLocationDegrees.self, forKey: .latitude)
        coordinate.longitude = try values.decode(CLLocationDegrees.self, forKey: .longitude)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let title = title {
            try container.encode(title, forKey: .title)
        }
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
    }
}
