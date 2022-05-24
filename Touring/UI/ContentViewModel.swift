import SwiftUI

class ContentViewModel: ObservableObject, LocationDelegate, LocationLoggerDelegate {
    let location = Location()

    @Published var prefersMile = false {
        didSet {
            updateSpeedNumber()
        }
    }
    @Published var isSpeedValid = false
    @Published var speedNumber = ""
    var speedUnit: String {
        return prefersMile ? "mph" : "km/h"
    }
    @Published var isCourseValid = false
    @Published var course = Angle.degrees(0)
    @Published var compassType = CompassType.heading {
        didSet {
            updateCourse()
        }
    }

    @Published var alertingLocationAuthorizationRestricted = false
    @Published var alertingLocationAuthorizationDenied = false
    @Published var alertingLocationAccuracy = false
    @Published var alertingLocationLoggingError = false
    @Published var loggingState = LocationLogger.State.stopped

    @Published var mapViewContext = MapViewContext()

    @Published var destinationDetail: DestinationDetail?
    @Published var showingDestinationDetail = false

    enum DistanceUnit: Int {
        case automatic, meters, miles
    }

    enum CompassType: Int {
        case heading, north
    }

    init() {
#if DEBUG
        if let uitest = ProcessInfo.processInfo.environment["UITEST"], uitest == "1" {
            try? FileManager.default.removeItem(at: FileManager.default.documentURL(of: "destinations.json"))
            for (key, _) in UserDefaults.standard.dictionaryRepresentation() {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
#endif

        location.delegate = self
        location.logger.delegate = self

        loadSettings()

        updateSpeedNumber()
        updateCourse()
        loggingStateChanged()
    }

    func loadSettings() {
        let distanceUnit = DistanceUnit(rawValue: UserDefaults.standard.integer(forKey: "distance_unit")) ?? .automatic
        switch distanceUnit {
        case .meters:
            prefersMile = false
        case .miles:
            prefersMile = true
        default:
            prefersMile = Locale.current.languageCode != "ja"
        }

        compassType = CompassType(rawValue: UserDefaults.standard.integer(forKey: "compass_type")) ?? .heading

        mapViewContext.showsAddress = (UserDefaults.standard.object(forKey: "show_address") as? Int ?? 1) != 0
    }

    func locationDidChangeAuthorization(_ location: Location) {
        if location.manager.authorizationStatus == .restricted {
            alertingLocationAuthorizationRestricted = true
        } else if location.manager.authorizationStatus == .denied {
            alertingLocationAuthorizationDenied = true
        } else if location.manager.accuracyAuthorization == .reducedAccuracy {
            alertingLocationAccuracy = true
        }
    }

    func updateSpeedNumber() {
        if let mps = location.last?.validSpeed {
            let val = prefersMile ? MeasureUtil.mphFrom(mps: mps) : MeasureUtil.kphFrom(mps: mps)
            speedNumber = MeasureUtil.displayString(val)
            isSpeedValid = true
        } else {
            speedNumber = MeasureUtil.displayString(0)
            isSpeedValid = false
        }
    }

    func updateCourse() {
        if let course = location.last?.validCourse {
            if compassType == .north {
                self.course = .degrees(-course)
            } else {
                self.course = .degrees(course - mapViewContext.heading)
            }
            isCourseValid = true
        } else {
            if compassType == .north {
                self.course = .degrees(0)
            } else {
                self.course = .degrees(-mapViewContext.heading)
            }
            isCourseValid = false
        }
    }

    func locationDidUpdate(_ location: Location) {
        updateSpeedNumber()
        updateCourse()
    }

    func loggingStateChanged() {
        loggingState = location.logger.state
    }

    func loggingDidFailWithError(_ error: Error) {
        alertingLocationLoggingError = true
    }
}
