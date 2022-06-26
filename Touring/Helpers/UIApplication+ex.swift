import UIKit

extension UIApplication {
    var keyWindow: UIWindow? {
        for scene in connectedScenes {
            if let kw = (scene as? UIWindowScene)?.keyWindow {
                return kw
            }
        }
        return nil
    }

    /// Open the Settings app and go to this app's individual page.
    func openSettings() {
        if let url = URL(string: Self.openSettingsURLString), canOpenURL(url) {
            open(url)
        }
    }
}
