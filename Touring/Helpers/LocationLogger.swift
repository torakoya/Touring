import CoreLocation
import Foundation

class LocationLogger {
    enum Error: Swift.Error {
        case fileIOError(original: Swift.Error?)
    }

    private var manager: CLLocationManager

    weak var delegate: LocationLoggerDelegate?

    var logPath: String?
    var isPaused = false

    enum State {
        case started, paused, stopped
    }

    var state: State {
        logPath != nil ? isPaused ? .paused : .started : .stopped
    }

    init(manager: CLLocationManager) {
        self.manager = manager
    }

    private static let logTimeFormatter = { () -> DateFormatter in
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZZZ"
        return fmt
    }()

    private static let logNameTimeFormatter = { () -> DateFormatter in
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "yyyyMMdd-HHmmss"
        return fmt
    }()

    private class func generateLogName(ext: String = "csv") -> String {
        let time = logNameTimeFormatter.string(from: Date())
        return "locations-\(time).\(ext)"
    }

    var isLogging: Bool {
        logPath != nil && !isPaused
    }

    /// Start logging either from stop or pause.
    func start() {
        if logPath == nil {
            logPath = Self.generateLogName()
        }
        isPaused = false

        if manager.authorizationStatus == .authorizedAlways {
            manager.allowsBackgroundLocationUpdates = true
        }

        delegate?.loggingStateChanged()
    }

    func pause() {
        if logPath != nil {
            isPaused = true
        }

        manager.allowsBackgroundLocationUpdates = false

        delegate?.loggingStateChanged()
    }

    func stop() {
        logPath = nil
        isPaused = false

        manager.allowsBackgroundLocationUpdates = false

        delegate?.loggingStateChanged()

        finalize()
    }

    func save(_ locations: [CLLocation], to path: String? = nil) {
        guard let path = (path != nil ? path : logPath) else { return }

        let url = FileManager.default.documentURL(of: path)

        if !FileManager.default.fileExists(atPath: url.path) {
            let header = "time,latitude,longitude,horizontalAccuracy," +
            "speed,speedAccuracy,course,courseAccuracy,altitude,verticalAccuracy\r\n"
            FileManager.default.createFile(atPath: url.path, contents: header.data(using: .utf8)!)
        }

        guard let file = FileHandle(forWritingAtPath: url.path) else {
            delegate?.loggingDidFailWithError(Error.fileIOError(original: nil))
            return
        }

        file.seekToEndOfFile()

        for location in locations {
            let timestamp = Self.logTimeFormatter.string(from: location.timestamp)
            let latitude = location.validLatitude.map { "\($0)" } ?? ""
            let longitude = location.validLongitude.map { "\($0)" } ?? ""
            let hacc = "\(location.horizontalAccuracy)"
            let speed = location.validSpeed.map { "\($0)" } ?? ""
            let sacc = "\(location.speedAccuracy)"
            let course = location.validCourse.map { "\($0)" } ?? ""
            let cacc = "\(location.courseAccuracy)"
            let altitude = location.validAltitude.map { "\($0)" } ?? ""
            let vacc = "\(location.verticalAccuracy)"

            let s = "\(timestamp),\(latitude),\(longitude),\(hacc)," +
            "\(speed),\(sacc),\(course),\(cacc),\(altitude),\(vacc)\r\n"
            do {
                try file.write(contentsOf: s.data(using: .utf8)!)
            } catch {
                delegate?.loggingDidFailWithError(Error.fileIOError(original: error))
            }
        }

        file.closeFile()
    }

    func finalize() {
        if !isLogging, let csvs = try? shouldFinalized() {
            Task.detached {
                for csv in csvs {
                    do {
                        try Self.convert(csv)
                    } catch {
                        // The error should be notified to the user if possible.
                    }
                }
            }
        }
    }

    func shouldFinalized() throws -> [String] {
        let files = try FileManager.default.contentsOfDirectory(atPath: FileManager.default.documentURL().path)
        let locations = files.filter { $0.hasPrefix("locations-") }
        let csvs = locations.filter { $0.hasSuffix(".csv") }
        let gpxs = locations.filter { $0.hasSuffix(".gpx") }.map { String($0.dropLast(3)) + "csv" }
        return csvs.subtracting(gpxs)
    }

    static func convert(_ name: String) throws {
        let outname2 = (!name.hasSuffix(".csv") ? name : String(name.dropLast(4))) + ".gpx"
        let outurl = FileManager.default.documentURL(of: outname2 + ".temp")
        let outurl2 = FileManager.default.documentURL(of: outname2)

        // If outurl already exists, createFile() will truncate it.
        if !FileManager.default.createFile(atPath: outurl.path, contents: nil) {
            throw Error.fileIOError(original: nil)
        }

        let inurl = FileManager.default.documentURL(of: name)
        let gpxwriter = try GPXTrackWriter(FileHandle(forWritingTo: outurl))

        try CSVReader.read(inurl) {
            var location = $0

            if let time = location["time"],
               let date = Self.logTimeFormatter.date(from: time) {
                location["time"] = date.formatted(.iso8601)
            } else {
                location.removeValue(forKey: "time")
            }

            try gpxwriter.writeLocation(location)
        }

        try gpxwriter.close(all: true)

        try FileManager.default.moveItem(at: outurl, to: outurl2)
    }
}

protocol LocationLoggerDelegate: AnyObject {
    func loggingStateChanged()
    func loggingDidFailWithError(_ error: Error)
}

extension LocationLoggerDelegate {
    func loggingDidFailWithError(_ error: Error) {}
}
