import Foundation

extension CharacterSet {
    static var urlQueryDataAllowed: CharacterSet {
        .urlQueryAllowed.subtracting(CharacterSet(charactersIn: "?&="))
    }
}
