import CoreLocation
import Foundation

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
        manager.distanceFilter = 5
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

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        last = locations.last
        logger.save(locations)
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
