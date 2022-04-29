import SwiftUI

class ContentViewModel: ObservableObject, LocationDelegate, LocationLoggerDelegate {
    let location = Location()

    @Published var prefersMile = UserDefaults.standard.bool(forKey: "prefersMile") {
        didSet {
            UserDefaults.standard.set(prefersMile, forKey: "prefersMile")
            updateSpeedNumber()
        }
    }
    @Published var speedNumber = ""
    var speedUnit: String {
        return prefersMile ? "mph" : "km/h"
    }
    @Published var course: Angle?

    @Published var alertingLocationAuthorizationRestricted = false
    @Published var alertingLocationAuthorizationDenied = false
    @Published var alertingLocationAccuracy = false
    @Published var alertingLocationLoggingError = false
    @Published var loggingState = LocationLogger.State.stopped

    init() {
        location.delegate = self
        location.logger.delegate = self

        updateSpeedNumber()
        updateCourse()
        loggingStateChanged()
    }

    func locationDidChangeAuthorization(_ location: Location) {
        if location.manager.authorizationStatus == .restricted {
            alertingLocationAuthorizationRestricted = true
        } else if location.manager.authorizationStatus == .denied {
            alertingLocationAuthorizationDenied = true
        } else if location.manager.accuracyAuthorization == .reducedAccuracy {
            alertingLocationAccuracy = true
        }
    }

    private func updateSpeedNumber() {
        if let mps = location.last?.speed, mps >= 0 {
            let val = mps * 60 * 60 / (prefersMile ? 1609.344 : 1000)
            speedNumber = String(format: "%.*f", val < 10 ? 1 : 0, val)
        } else {
            speedNumber = "-"
        }
    }

    private func updateCourse() {
        if let loc = location.last, loc.courseAccuracy >= 0, loc.course >= 0 {
            course = .degrees(loc.course)
        } else {
            course = nil
        }
    }

    func locationDidUpdate(_ location: Location) {
        updateSpeedNumber()
        updateCourse()
    }

    func loggingStateChanged() {
        loggingState = location.logger.state
    }

    func loggingDidFailWithError(_ error: Error) {
        alertingLocationLoggingError = true
    }

    /// Open the Settings app.
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}
