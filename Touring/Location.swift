import CoreLocation
import Foundation

/// The location manager.
class Location: NSObject {
    let manager = CLLocationManager()
    weak var delegate: LocationDelegate?

    override init() {
        super.init()

        manager.activityType = .automotiveNavigation
        manager.distanceFilter = 5
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.pausesLocationUpdatesAutomatically = false
        manager.delegate = self
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
}

/// The methods that receive location events.
protocol LocationDelegate: AnyObject {
    /// Tells the delegate that the location authorization status has been changed.
    func locationDidChangeAuthorization(_ location: Location)
}

extension LocationDelegate {
    func locationDidChangeAuthorization(_ location: Location) {}
}
