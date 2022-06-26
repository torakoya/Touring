import Foundation

extension Array {
    func subtracting<S>(_ others: S) -> [Element] where S: Sequence, Element: Equatable, S.Element == Element {
        filter { !others.contains($0) }
    }
}
