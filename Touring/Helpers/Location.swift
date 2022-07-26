import CoreLocation
import Foundation

/// The location manager.
class Location: NSObject {
    /// The last location data.
    private(set) var last: CLLocation?

    private var lastLoggedData: CLLocation?

    let manager = CLLocationManager()
    weak var delegate: LocationDelegate?
    lazy var logger = LocationLogger(manager: manager)

    override init() {
        super.init()

        manager.activityType = .automotiveNavigation
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.pausesLocationUpdatesAutomatically = false
        manager.delegate = self
    }

    func bookmarkLastLocation() {
        guard let location = last else { return }

        logger.save([location], to: "bookmarks.csv")
    }
}

extension Location: CLLocationManagerDelegate {
    /// Provides the common actions for the authorization state changes.
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .notDetermined {
            manager.requestAlwaysAuthorization()
        } else if manager.authorizationStatus == .authorizedAlways ||
                    manager.authorizationStatus == .authorizedWhenInUse {
            manager.startUpdatingLocation()
        }

        delegate?.locationDidChangeAuthorization(self)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Ignore errors.
    }

    func shouldAccept(_ location: CLLocation, last: CLLocation?) -> Bool {
        // Accept if the last location is empty.
        guard let last = last else {
            return true
        }

        // Accept if it is far from the last location.
        if location.validLatitude != nil && last.validLatitude != nil &&
            location.distance(from: last) >= 5 {
            return true
        }

        // Now look at the speed to make sure zero speed will be logged
        // when the user stops.

        // Reject if the speed is invalid. The current speed check has
        // priority over the last speed one.
        guard let speed = location.validSpeed else {
            return false
        }

        // Accept if the last speed is invalid.
        guard let lastSpeed = last.validSpeed else {
            return true
        }

        // Accept if the speed changes from nonzero to zero.
        if lastSpeed > 0 && speed == 0 {
            return true
        }

        // Anything else is unnecessary.
        return false
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        var finalLocations: [CLLocation] = []
        var lastLocation = lastLoggedData
        var lastUpdated = false

        for location in locations {
            // Ignore if it contains no valid data.
            if location.validLatitude == nil && location.validSpeed == nil &&
                location.validCourse == nil && location.validAltitude == nil {
                continue
            }

            last = location
            lastUpdated = true

            if shouldAccept(location, last: lastLocation) {
                finalLocations += [location]
                lastLocation = location
            }
        }

        finalLocations.last.map {
            lastLoggedData = $0
            logger.save(finalLocations)
        }

        if lastUpdated {
            delegate?.locationDidUpdate(self)
        }
    }
}

/// The methods that receive location events.
protocol LocationDelegate: AnyObject {
    /// Tells the delegate that the location authorization status has been changed.
    func locationDidChangeAuthorization(_ location: Location)

    /// Tells the delegate that new location data has arrived.
    func locationDidUpdate(_ location: Location)
}

extension LocationDelegate {
    func locationDidChangeAuthorization(_ location: Location) {}
    func locationDidUpdate(_ location: Location) {}
}
