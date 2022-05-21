import UIKit

extension UIApplication {
    /// Open the Settings app and go to this app's individual page.
    func openSettings() {
        if let url = URL(string: Self.openSettingsURLString), canOpenURL(url) {
            open(url)
        }
    }
}
