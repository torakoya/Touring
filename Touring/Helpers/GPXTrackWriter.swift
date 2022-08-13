import Foundation

/// Writes a GPX file containing tracks.
class GPXTrackWriter {
    var creator = "GPXTrackWriter"
    var includingGpxtpx = false
    var includingCllocation = false
    var indentWidth = 2
    var lineSeparator = "\n"

    private let file: FileHandle
    private var headerWritten = false

    init(_ file: FileHandle) {
        self.file = file
    }

    private func write(_ str: String) throws {
        try file.write(contentsOf: Data(str.utf8))
    }

    private func writeLine(_ str: String) throws {
        try write(str + lineSeparator)
    }

    private func writeValue(_ indent: Int, _ key: String, _ value: String?) throws {
        guard let value = value, !value.isEmpty else { return }
        try writeLine(i(indent) + "<\(key)>\(value)</\(key)>")
    }

    /// Returns an indent string.
    private func i(_ level: Int) -> String {
        String(repeating: " ", count: indentWidth * level)
    }

    private func xmlStringLiteral(_ str: String) -> String {
        str.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    private func writeHeader() throws {
        var ns = #"xmlns="http://www.topografix.com/GPX/1/1""#

        if includingGpxtpx {
            ns += #" xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v2""#
        }
        if includingCllocation {
            ns += #" xmlns:cllocation="http://tora.ac/touring/1""#
        }

        let header = """
            <?xml version="1.0" encoding="UTF-8"?>\(lineSeparator)\
            <gpx version="1.1" creator="\(xmlStringLiteral(creator))" \(ns)>\(lineSeparator)\
            \(i(1))<trk>\(lineSeparator)\
            \(i(2))<trkseg>
            """
        try writeLine(header)
    }

    private func writeFooter() throws {
        let footer = """
        \(i(2))</trkseg>\(lineSeparator)\
        \(i(1))</trk>\(lineSeparator)\
        </gpx>
        """
        try writeLine(footer)
    }

    func close(all: Bool = false) throws {
        if headerWritten { try writeFooter() }
        if all { try file.close() }
    }

    func writeLocation(_ location: [String: String]) throws {
        // CLLocation's initializer is hard to use when some of the
        // members can be empty, so receive data as a dictionary.

        // Handle only locations that have both latitude and longitude.
        guard let lat = location["latitude"], !lat.isEmpty,
              let lon = location["longitude"], !lon.isEmpty else { return }

        if !headerWritten {
            try writeHeader()
            headerWritten = true
        }

        try writeLine(i(3) + "<trkpt lat=\"\(lat)\" lon=\"\(lon)\">")

        try writeValue(4, "ele", location["altitude"])
        try writeValue(4, "time", location["timestamp"])

        var gpxtpx = [(key: String, value: String)]()

        if includingGpxtpx {
            gpxtpx += ["speed", "course"].compactMap { key in
                location[key].map { (key: key, value: $0) }
            }.filter { !$0.value.isEmpty }
        }

        var myext = [(key: String, value: String)]()

        if includingCllocation {
            myext += ["horizontalAccuracy", "verticalAccuracy", "speedAccuracy", "courseAccuracy"].compactMap { key in
                location[key].map { (key: key, value: $0) }
            }.filter { !$0.value.isEmpty }
        }

        if !gpxtpx.isEmpty || !myext.isEmpty {
            try writeLine(i(4) + "<extensions>")
            if !gpxtpx.isEmpty {
                try writeLine(i(5) + "<gpxtpx:TrackPointExtension>")
                for kv in gpxtpx {
                    try writeValue(6, "gpxtpx:\(kv.key)", kv.value)
                }
                try writeLine(i(5) + "</gpxtpx:TrackPointExtension>")
            }
            for kv in myext {
                try writeValue(5, "cllocation:\(kv.key)", kv.value)
            }
            try writeLine(i(4) + "</extensions>")
        }

        try writeLine(i(3) + "</trkpt>")
    }
}
