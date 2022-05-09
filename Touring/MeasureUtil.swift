import CoreLocation
import Foundation

enum MeasureUtil {
    static func kphFrom(mps: CLLocationSpeed) -> CLLocationSpeed {
        mps * 60 * 60 / 1000
    }

    static func mphFrom(mps: CLLocationSpeed) -> CLLocationSpeed {
        mps * 60 * 60 / 1609.344
    }

    static func milesFrom(meters: CLLocationDistance) -> CLLocationDistance {
        meters / 1609.344
    }

    static func feetFrom(meters: CLLocationDistance) -> CLLocationDistance {
        meters / 0.3048
    }

    /// Returns a string that represents a pretty-rounded number.
    ///
    /// * If the integer part of the number has a single digit, the
    ///   fractional part of the result has a single digit, otherwise no
    ///   digit.
    /// * Keeping the fractional part is preferable since it is more
    ///   informative. For example, if the number is 9.94, the result will
    ///   be "9.9", not "10".
    /// * If the number is zero, the result will be "0", not "0.0".
    /// * If the number is x.000, the result will be "x.0", not "x". FYI,
    ///   Apple Maps seems to prefer "x.0" and Google Maps "x".
    static func displayString(_ number: Double) -> String {
        let digits1 = round(number * 10) / 10

        if digits1 < 10 && digits1 != 0 {
            return String(format: "%.1f", digits1) // "a.x"
        } else {
            return String(Int(round(number))) // "ab"
        }
    }

    static func metersString(_ meters: CLLocationDistance) -> [String] {
        let rmeters = Int(round(meters))

        if rmeters < 1000 {
            return [String(rmeters), "m"]
        } else {
            return [displayString(meters / 1000), "km"]
        }
    }

    static func milesString(meters: CLLocationDistance) -> [String] {
        let feet = Int(round(feetFrom(meters: meters)))

        if feet < 1000 {
            return [String(feet), "ft"]
        } else {
            return [displayString(milesFrom(meters: meters)), "mi"]
        }
    }

    static func distanceString(meters: CLLocationDistance, prefersMile: Bool = false) -> [String] {
        prefersMile ? milesString(meters: meters) : metersString(meters)
    }

    /// Returns the rough distance.
    static func distance(from l1: CLLocation, to l2: CLLocation) -> CLLocationDistance {
        // The result is the average of the two below:
        //
        // * The diagonal distance, which would be the minimum.
        // * The horizontal distance + the vertical distance, which
        //   would be the maximum.

        let mindist = l1.distance(from: l2)

        let latdist = l1.distance(from: CLLocation(
            latitude: l2.coordinate.latitude,
            longitude: l1.coordinate.longitude))
        let londist = l1.distance(from: CLLocation(
            latitude: l1.coordinate.latitude,
            longitude: l2.coordinate.longitude))
        let maxdist = latdist + londist

        return (mindist + maxdist) / 2
    }
}
