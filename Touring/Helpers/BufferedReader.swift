import Foundation

/// The line-oriented reader.
class BufferedReader {
    var chunkSize = 8192
    var separator = UInt8(ascii: "\n")

    let fileHandle: FileHandle
    private var buffer = Data()

    init(_ fileHandle: FileHandle) {
        self.fileHandle = fileHandle
    }

    func readLine() throws -> Data? {
        while !buffer.contains(separator) {
            guard let data = try fileHandle.read(upToCount: chunkSize) else { break }
            buffer += data
        }
        if buffer.isEmpty {
            return nil
        } else if let index = buffer.firstIndex(of: separator) {
            let data = buffer[0...index]
            buffer.removeSubrange(0...index)
            return data
        } else {
            return buffer
        }
    }
}
