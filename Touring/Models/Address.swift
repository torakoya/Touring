import CoreLocation

class Address {
    struct Result {
        private(set) var address: [String?]

        private(set) var fetchLocation: CLLocation
        private(set) var fetchTime: Date
    }

    static let minimumFetchDistance = 10.0
    static let minimumFetchWait = 10.0

    typealias CompletionHandler = (Result?, Error?) -> Void

    private static let geocoder = CLGeocoder()

    private(set) static var result: Result?
    private(set) static var nextFetchTime = Date(timeIntervalSince1970: 0)

    static func canFetch(location: CLLocation) -> Bool {
        Date() >= nextFetchTime &&
        result.map { location.distance(from: $0.fetchLocation) >= minimumFetchDistance } ?? true
    }

    static func fetch(location: CLLocation, onComplete: @escaping CompletionHandler) {
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            let now = Date()
            nextFetchTime = now + minimumFetchWait

            if let error = error {
                onComplete(nil, error)
            } else if let placemark = placemarks?.first {
                let result = Result(
                    address: [placemark.administrativeArea, placemark.locality, placemark.subLocality],
                    fetchLocation: location, fetchTime: now)
                self.result = result
                onComplete(result, nil)
            }
        }
    }
}
