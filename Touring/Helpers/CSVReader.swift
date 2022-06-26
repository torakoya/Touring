import Foundation

class CSVReader {
    enum Error: Swift.Error {
        case encodingError
    }

    typealias RowHandler = ([String: String]) throws -> Void

    static func read(_ url: URL, handler: RowHandler) throws {
        var headers: [String]?

        let file = try BufferedReader(FileHandle(forReadingFrom: url))
        while let line = try file.readLine() {
            // Not .dropLast(2), since String treats "\r\n" as a single character.
            guard let str = String(data: line, encoding: .utf8)?.dropLast() else {
                throw Error.encodingError
            }

            if let headers = headers {
                let values = str.split(separator: ",", omittingEmptySubsequences: false).map { String($0) }

                let dict = Dictionary(uniqueKeysWithValues: zip(headers, values))
                try handler(dict)
            } else {
                headers = str.split(separator: ",", omittingEmptySubsequences: false).map { String($0) }
            }
        }
        try file.fileHandle.close()
    }
}
