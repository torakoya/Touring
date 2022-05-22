import Foundation

extension FileManager {
    /// Returns a URL for the path in the document directory.
    /// - Parameter path: A relative path based on the document directory.
    func documentURL(of path: String? = nil) -> URL {
        let url = urls(for: .documentDirectory, in: .userDomainMask)[0]
        if let path = path {
            return url.appendingPathComponent(path)
        } else {
            return url
        }
    }
}
