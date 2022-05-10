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
    }

    func save(_ locations: [CLLocation], to path: String? = nil) {
        guard let path = (path != nil ? path : logPath) else { return }

        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first!.appendingPathComponent(path)

        if !FileManager.default.fileExists(atPath: url.path) {
            let header = "time,latitude,longitude,speed,course,altitude," +
                "floorLevel,horizontalAccuracy,verticalAccuracy\r\n"
            FileManager.default.createFile(atPath: url.path, contents: header.data(using: .utf8)!)
        }

        guard let file = FileHandle(forWritingAtPath: url.path) else {
            delegate?.loggingDidFailWithError(Error.fileIOError(original: nil))
            return
        }

        file.seekToEndOfFile()

        for location in locations {
            let timestamp = type(of: self).logTimeFormatter.string(from: location.timestamp)
            let latitude = location.horizontalAccuracy >= 0 ? "\(location.coordinate.latitude)" : ""
            let longitude = location.horizontalAccuracy >= 0 ? "\(location.coordinate.longitude)" : ""
            let speed = location.speed >= 0 ? "\(location.speed)" : ""
            let course = location.course >= 0 ? "\(location.course)" : ""
            let altitude = location.verticalAccuracy > 0 ?  "\(location.altitude)" : ""
            let floor = location.floor != nil ? "\(location.floor!.level)" : ""
            let hacc = "\(location.horizontalAccuracy)"
            let vacc = "\(location.verticalAccuracy)"

            let s = "\(timestamp),\(latitude),\(longitude),\(speed),\(course),\(altitude),\(floor),\(hacc),\(vacc)\r\n"
            do {
                try file.write(contentsOf: s.data(using: .utf8)!)
            } catch {
                delegate?.loggingDidFailWithError(Error.fileIOError(original: error))
            }
        }

        file.closeFile()
    }
}

protocol LocationLoggerDelegate: AnyObject {
    func loggingStateChanged()
    func loggingDidFailWithError(_ error: Error)
}

extension LocationLoggerDelegate {
    func loggingDidFailWithError(_ error: Error) {}
}
