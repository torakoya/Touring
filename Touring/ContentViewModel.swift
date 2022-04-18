import UIKit

class ContentViewModel: ObservableObject, LocationDelegate {
    let location = Location()
    @Published var speedNumber = "-"
    @Published var speedUnit = "km/h"
    @Published var alertingLocationAuthorizationRestricted = false
    @Published var alertingLocationAuthorizationDenied = false
    @Published var alertingLocationAccuracy = false

    init() {
        location.delegate = self
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

    func locationDidUpdate(_ location: Location) {
        if let mps = location.last?.speed, mps >= 0 {
            let kph = mps * 60 * 60 / 1000
            speedNumber = String(format: "%.*f", kph < 10 ? 1 : 0, kph)
        }
    }

    /// Open the Settings app.
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}
