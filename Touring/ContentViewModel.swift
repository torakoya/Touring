import UIKit

class ContentViewModel: ObservableObject, LocationDelegate {
    let location = Location()
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

    /// Open the Settings app.
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}
