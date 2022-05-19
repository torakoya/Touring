import MapKit

class Route {
    struct Result {
        private(set) var from: CLLocation
        private(set) var to: CLLocation
        private(set) var routes: [Polyline]
        private(set) var distance: CLLocationDistance
        private(set) var time: TimeInterval

        fileprivate init(from: CLLocation, to: CLLocation, response: MKDirections.Response) {
            self.from = from
            self.to = to
            self.routes = response.routes.map { Polyline($0) }
            self.routes.first?.isFirst = true
            self.distance = response.routes[0].distance
            self.time = response.routes[0].expectedTravelTime
        }
    }

    class Polyline: MKPolyline {
        private(set) var advisoryNotices: [String] = []
        fileprivate(set) var isFirst = false

        fileprivate convenience init(_ route: MKRoute) {
            self.init(points: route.polyline.points(), count: route.polyline.pointCount)
            advisoryNotices = route.advisoryNotices
        }
    }

    enum Error: Swift.Error {
        case shortIntervalError
    }

    static let minimumFetchDistance = 5.0
    static let minimumFetchWait = 5.0

    private(set) static var nextFetchTime = Date(timeIntervalSince1970: 0)

    static func canFetch(from: CLLocation, to: CLLocation, before: Result?) -> Bool {
        return Date() >= nextFetchTime &&
        before.map {
            from.distance(from: $0.from) >= minimumFetchDistance ||
            to.distance(from: $0.to) > 0 // `to` has changed
        } ?? true
    }

    private static var task: Task<Result, Swift.Error>?

    static func fetch(from: CLLocation, to: CLLocation, byForce: Bool = false) async throws -> Result {
        task?.cancel()

        task = Task {
            do {
                if Date() < nextFetchTime {
                    if byForce {
                        try await Task.sleep(nanoseconds: UInt64(nextFetchTime.timeIntervalSinceNow) * 1_000_000_000)
                    } else {
                        throw Error.shortIntervalError
                    }
                }

                let req = MKDirections.Request()
                req.source = MKMapItem(placemark: MKPlacemark(coordinate: from.coordinate))
                req.destination = MKMapItem(placemark: MKPlacemark(coordinate: to.coordinate))
                req.transportType = .automobile
                req.requestsAlternateRoutes = true

                let dirs = MKDirections(request: req)
                let response = try await dirs.calculate()
                nextFetchTime = Date() + minimumFetchWait
                return Result(from: from, to: to, response: response)
            } catch {
                throw error
            }
        }
        return try await task!.value
    }
}
