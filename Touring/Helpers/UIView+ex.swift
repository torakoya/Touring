import UIKit

extension UIView {
    var upperViews: [UIView] {
        // layer.zPosition is ignored but it should also be considered in principle.
        if let superview = self.superview,
           let index = superview.subviews.firstIndex(of: self) {
            return superview.subviews.dropFirst(index + 1) + superview.upperViews
        }
        return []
    }
}
