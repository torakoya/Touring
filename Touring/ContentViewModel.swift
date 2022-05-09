import SwiftUI

class ContentViewModel: ObservableObject, LocationDelegate, LocationLoggerDelegate {
    let location = Location()

    @Published var prefersMile = UserDefaults.standard.bool(forKey: "prefersMile") {
        didSet {
            UserDefaults.standard.set(prefersMile, forKey: "prefersMile")
            updateSpeedNumber()
        }
    }
    @Published var isSpeedValid = false
    @Published var speedNumber = ""
    var speedUnit: String {
        return prefersMile ? "mph" : "km/h"
    }
    @Published var isCourseValid = false
    @Published var course = Angle.degrees(0)

    @Published var alertingLocationAuthorizationRestricted = false
    @Published var alertingLocationAuthorizationDenied = false
    @Published var alertingLocationAccuracy = false
    @Published var alertingLocationLoggingError = false
    @Published var loggingState = LocationLogger.State.stopped

    @Published var mapViewContext = MapViewContext()

    @Published var destinationDetail: DestinationDetail?
    @Published var showingDestinationDetail = false

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

    func updateSpeedNumber() {
        if let mps = location.last?.speed, mps >= 0 {
            let val = prefersMile ? MeasureUtil.mphFrom(mps: mps) : MeasureUtil.kphFrom(mps: mps)
            speedNumber = MeasureUtil.displayString(val)
            isSpeedValid = true
        } else {
            speedNumber = MeasureUtil.displayString(0)
            isSpeedValid = false
        }
    }

    func updateCourse() {
        if let loc = location.last, loc.courseAccuracy >= 0, loc.course >= 0 {
            course = .degrees(loc.course - mapViewContext.heading)
            isCourseValid = true
        } else {
            course = .degrees(-mapViewContext.heading)
            isCourseValid = false
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
