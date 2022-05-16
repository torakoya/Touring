import CoreLocation

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
