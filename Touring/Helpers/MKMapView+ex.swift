import MapKit

extension MKMapView {
    func tappedAnnotations(at point: CGPoint) -> [MKAnnotation] {
        let size = 40.0
        let rect = CGRect(x: point.x - size / 2, y: point.y - size / 2, width: size, height: size)

        return annotations.filter {
            if let view = view(for: $0), !view.isHidden {
                let apoint = convert($0.coordinate, toPointTo: self)
                return rect.contains(apoint)
            }
            return false
        }
    }
}
