import CoreLocation
import Foundation

extension CLLocation {
    var validLatitude: CLLocationDegrees? {
        horizontalAccuracy < 0 ? nil : coordinate.latitude
    }

    var validLongitude: CLLocationDegrees? {
        horizontalAccuracy < 0 ? nil : coordinate.longitude
    }

    var validSpeed: CLLocationSpeed? {
        speedAccuracy < 0 || speed < 0 ? nil : speed
    }

    var validCourse: CLLocationDirection? {
        courseAccuracy < 0 || course < 0 ? nil : course
    }

    var validAltitude: CLLocationDistance? {
        verticalAccuracy <= 0 ? nil : altitude
    }
}

/// The location manager.
class Location: NSObject {
    /// The last location data.
    private(set) var last: CLLocation?

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

        // Now look at the speed to make sure the speedometer shows
        // zero when the user stops.

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

        // Accept if the displayed speed in the speedometer changes
        // from nonzero to zero. 0.01 mps is less than both 0.05 km/h
        // and 0.05 mph.
        if lastSpeed >= 0.01 && speed < 0.01 {
            return true
        }

        // Anything else is unnecessary.
        return false
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        var finalLocations: [CLLocation] = []
        var lastLocation = last

        for location in locations {
            // Ignore if it contains no valid data.
            if location.validLatitude == nil && location.validSpeed == nil &&
                location.validCourse == nil && location.validAltitude == nil {
                continue
            }

            if shouldAccept(location, last: lastLocation) {
                finalLocations += [location]
                lastLocation = location
            }
        }

        finalLocations.last.map { last = $0 }
        logger.save(finalLocations)
        delegate?.locationDidUpdate(self)
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
