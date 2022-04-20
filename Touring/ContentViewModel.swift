import UIKit

class ContentViewModel: ObservableObject, LocationDelegate {
    let location = Location()

    @Published var prefersMile = false {
        didSet {
            updateSpeedNumber()
        }
    }
    @Published var speedNumber = ""
    var speedUnit: String {
        return prefersMile ? "mph" : "km/h"
    }

    @Published var alertingLocationAuthorizationRestricted = false
    @Published var alertingLocationAuthorizationDenied = false
    @Published var alertingLocationAccuracy = false

    init() {
        location.delegate = self
        updateSpeedNumber()
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

    func locationDidUpdate(_ location: Location) {
        updateSpeedNumber()
    }

    /// Open the Settings app.
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}
