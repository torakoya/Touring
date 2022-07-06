import CoreLocation

extension CLLocation {
    var validHorizontalAccuracy: CLLocationAccuracy? {
        horizontalAccuracy < 0 ? nil : horizontalAccuracy
    }

    var validLatitude: CLLocationDegrees? {
        validHorizontalAccuracy == nil ? nil : coordinate.latitude
    }

    var validLongitude: CLLocationDegrees? {
        validHorizontalAccuracy == nil ? nil : coordinate.longitude
    }

    var validSpeedAccuracy: CLLocationSpeedAccuracy? {
        speedAccuracy < 0 ? nil : speedAccuracy
    }

    var validSpeed: CLLocationSpeed? {
        validSpeedAccuracy == nil || speed < 0 ? nil : speed
    }

    var validCourseAccuracy: CLLocationDirectionAccuracy? {
        courseAccuracy < 0 ? nil : courseAccuracy
    }

    var validCourse: CLLocationDirection? {
        validCourseAccuracy == nil || course < 0 ? nil : course
    }

    var validVerticalAccuracy: CLLocationAccuracy? {
        verticalAccuracy <= 0 ? nil: verticalAccuracy
    }

    var validAltitude: CLLocationDistance? {
        validVerticalAccuracy == nil ? nil : altitude
    }
}
