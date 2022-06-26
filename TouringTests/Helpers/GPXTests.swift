import XCTest
@testable import Touring

class GPXTests: XCTestCase {
    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: FileManager.default.documentURL(of: "test.gpx"))
        try? FileManager.default.removeItem(at: FileManager.default.documentURL(of: "test.csv"))
    }

    func gpx(_ name: String = "test.gpx") throws -> GPXTrackWriter {
        let url = FileManager.default.documentURL(of: name)

        XCTAssert(FileManager.default.createFile(atPath: url.path, contents: nil))

        return try GPXTrackWriter(FileHandle(forWritingTo: url))
    }

    func actual(_ name: String = "test.gpx") throws -> String {
        let url = FileManager.default.documentURL(of: name)
        let data = FileManager.default.contents(atPath: url.path)!
        return String(data: data, encoding: .utf8)!
    }

    func testEmpty() throws {
        let gpx = try gpx()
        let location = [String: String]()
        try gpx.writeLocation(location)
        try gpx.close(all: true)

        try XCTAssertEqual(actual(), "")
    }

    func testOnlyLat() throws {
        let gpx = try gpx()
        var location = [String: String]()
        location["latitude"] = "1"
        try gpx.writeLocation(location)
        try gpx.close(all: true)

        try XCTAssertEqual(actual(), "")
    }

    func testOnlyLon() throws {
        let gpx = try gpx()
        var location = [String: String]()
        location["longitude"] = "2"
        try gpx.writeLocation(location)
        try gpx.close(all: true)

        try XCTAssertEqual(actual(), "")
    }

    func testOnlyLatAndLon() throws {
        let gpx = try gpx()
        var location = [String: String]()
        location["latitude"] = "1"
        location["longitude"] = "2"
        try gpx.writeLocation(location)
        try gpx.close(all: true)

        try XCTAssertEqual(actual(), """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="Tora Touring" xmlns="http://www.topografix.com/GPX/1/1">
          <trk>
            <trkseg>
              <trkpt lat="1" lon="2">
              </trkpt>
            </trkseg>
          </trk>
        </gpx>

        """)
    }

    func testIndent() throws {
        let gpx = try gpx()
        gpx.indentWidth = 0
        var location = [String: String]()
        location["latitude"] = "1"
        location["longitude"] = "2"
        try gpx.writeLocation(location)
        try gpx.close(all: true)

        try XCTAssertFalse(actual().contains("\n "))
    }

    func testLineSeparator() throws {
        let gpx = try gpx()
        gpx.lineSeparator = "\r\n"
        var location = [String: String]()
        location["latitude"] = "1"
        location["longitude"] = "2"
        try gpx.writeLocation(location)
        try gpx.close(all: true)

        try XCTAssertEqual(actual().split(separator: "\r\n").count, 9)
    }

    func testNamespaceWithGpxtpx() throws {
        let gpx = try gpx()
        gpx.includingGpxtpx = true
        var location = [String: String]()
        location["latitude"] = "1"
        location["longitude"] = "2"
        try gpx.writeLocation(location)
        try gpx.close(all: true)

        try XCTAssert(actual().contains(
            #" xmlns="http://www.topografix.com/GPX/1/1""#))
        try XCTAssert(actual().contains(
            #" xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v2""#))
        try XCTAssertFalse(actual().contains(
            #" xmlns:cllocation="http://tora.ac/touring/1""#))
    }

    func testNamespaceWithCllocation() throws {
        let gpx = try gpx()
        gpx.includingCllocation = true
        var location = [String: String]()
        location["latitude"] = "1"
        location["longitude"] = "2"
        try gpx.writeLocation(location)
        try gpx.close(all: true)

        try XCTAssert(actual().contains(
            #" xmlns="http://www.topografix.com/GPX/1/1""#))
        try XCTAssertFalse(actual().contains(
            #" xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v2""#))
        try XCTAssert(actual().contains(
            #" xmlns:cllocation="http://tora.ac/touring/1""#))
    }

    func testNamespaceWithGpxtpxAndCllocation() throws {
        let gpx = try gpx()
        gpx.includingGpxtpx = true
        gpx.includingCllocation = true
        var location = [String: String]()
        location["latitude"] = "1"
        location["longitude"] = "2"
        try gpx.writeLocation(location)
        try gpx.close(all: true)

        try XCTAssert(actual().contains(
            #" xmlns="http://www.topografix.com/GPX/1/1""#))
        try XCTAssert(actual().contains(
            #" xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v2""#))
        try XCTAssert(actual().contains(
            #" xmlns:cllocation="http://tora.ac/touring/1""#))
    }

    func testEmptyEle() throws {
        let gpx = try gpx()
        var location = [String: String]()
        location["latitude"] = "1"
        location["longitude"] = "2"
        location["altitude"] = ""
        try gpx.writeLocation(location)
        try gpx.close(all: true)

        try XCTAssertFalse(actual().contains("<ele>"))
    }

    func testValidEle() throws {
        let gpx = try gpx()
        var location = [String: String]()
        location["latitude"] = "1"
        location["longitude"] = "2"
        location["altitude"] = "3"
        try gpx.writeLocation(location)
        try gpx.close(all: true)

        try XCTAssert(actual().contains("<ele>3</ele>"))
    }

    func testEmptyTime() throws {
        let gpx = try gpx()
        var location = [String: String]()
        location["latitude"] = "1"
        location["longitude"] = "2"
        location["time"] = ""
        try gpx.writeLocation(location)
        try gpx.close(all: true)

        try XCTAssertFalse(actual().contains("<time>"))
    }

    func testValidTime() throws {
        let gpx = try gpx()
        var location = [String: String]()
        location["latitude"] = "1"
        location["longitude"] = "2"
        location["time"] = "2021-06-21T21:10:15Z"
        try gpx.writeLocation(location)
        try gpx.close(all: true)

        try XCTAssert(actual().contains("<time>2021-06-21T21:10:15Z</time>"))
    }

    func testEmptySpeed() throws {
        let gpx = try gpx()
        gpx.includingGpxtpx = true
        var location = [String: String]()
        location["latitude"] = "1"
        location["longitude"] = "2"
        location["speed"] = ""
        try gpx.writeLocation(location)
        try gpx.close(all: true)

        let actual = try actual()
        XCTAssertFalse(actual.contains("<extensions>"))
        XCTAssertFalse(actual.contains("<gpxtpx:TrackPointExtension>"))
        XCTAssertFalse(actual.contains("<gpxtpx:speed>"))
    }

    func testValidSpeedWithGpxtpx() throws {
        let gpx = try gpx()
        gpx.includingGpxtpx = true
        var location = [String: String]()
        location["latitude"] = "1"
        location["longitude"] = "2"
        location["speed"] = "3"
        try gpx.writeLocation(location)
        try gpx.close(all: true)

        let actual = try actual()
        XCTAssert(actual.contains("<extensions>"))
        XCTAssert(actual.contains("<gpxtpx:TrackPointExtension>"))
        XCTAssert(actual.contains("<gpxtpx:speed>3</gpxtpx:speed>"))
    }

    func testValidSpeedWithoutGpxtpx() throws {
        let gpx = try gpx()
        gpx.includingGpxtpx = false
        var location = [String: String]()
        location["latitude"] = "1"
        location["longitude"] = "2"
        location["speed"] = "3"
        try gpx.writeLocation(location)
        try gpx.close(all: true)

        let actual = try actual()
        XCTAssertFalse(actual.contains("<extensions>"))
        XCTAssertFalse(actual.contains("<gpxtpx:TrackPointExtension>"))
        XCTAssertFalse(actual.contains("<gpxtpx:speed>"))
    }

    func testEmptyCourse() throws {
        let gpx = try gpx()
        gpx.includingGpxtpx = true
        var location = [String: String]()
        location["latitude"] = "1"
        location["longitude"] = "2"
        location["course"] = ""
        try gpx.writeLocation(location)
        try gpx.close(all: true)

        let actual = try actual()
        XCTAssertFalse(actual.contains("<extensions>"))
        XCTAssertFalse(actual.contains("<gpxtpx:TrackPointExtension>"))
        XCTAssertFalse(actual.contains("<gpxtpx:course>"))
    }

    func testValidCourseWithGpxtpx() throws {
        let gpx = try gpx()
        gpx.includingGpxtpx = true
        var location = [String: String]()
        location["latitude"] = "1"
        location["longitude"] = "2"
        location["course"] = "3"
        try gpx.writeLocation(location)
        try gpx.close(all: true)

        let actual = try actual()
        XCTAssert(actual.contains("<extensions>"))
        XCTAssert(actual.contains("<gpxtpx:TrackPointExtension>"))
        XCTAssert(actual.contains("<gpxtpx:course>3</gpxtpx:course>"))
    }

    func testValidCourseWithoutGpxtpx() throws {
        let gpx = try gpx()
        gpx.includingGpxtpx = false
        var location = [String: String]()
        location["latitude"] = "1"
        location["longitude"] = "2"
        location["course"] = "3"
        try gpx.writeLocation(location)
        try gpx.close(all: true)

        let actual = try actual()
        XCTAssertFalse(actual.contains("<extensions>"))
        XCTAssertFalse(actual.contains("<gpxtpx:TrackPointExtension>"))
        XCTAssertFalse(actual.contains("<gpxtpx:course>"))
    }

    func testEmptyHorizontalAccuracy() throws {
        let gpx = try gpx()
        gpx.includingCllocation = true
        var location = [String: String]()
        location["latitude"] = "1"
        location["longitude"] = "2"
        location["horizontalAccuracy"] = ""
        try gpx.writeLocation(location)
        try gpx.close(all: true)

        let actual = try actual()
        XCTAssertFalse(actual.contains("<extensions>"))
        XCTAssertFalse(actual.contains("<cllocation:horizontalAccuracy>"))
    }

    func testValidHorizontalAccuracyWithCllocation() throws {
        let gpx = try gpx()
        gpx.includingCllocation = true
        var location = [String: String]()
        location["latitude"] = "1"
        location["longitude"] = "2"
        location["horizontalAccuracy"] = "3"
        try gpx.writeLocation(location)
        try gpx.close(all: true)

        let actual = try actual()
        XCTAssert(actual.contains("<extensions>"))
        XCTAssert(actual.contains("<cllocation:horizontalAccuracy>3</cllocation:horizontalAccuracy>"))
    }

    func testValidHorizontalAccuracyWithoutCllocation() throws {
        let gpx = try gpx()
        gpx.includingCllocation = false
        var location = [String: String]()
        location["latitude"] = "1"
        location["longitude"] = "2"
        location["horizontalAccuracy"] = "3"
        try gpx.writeLocation(location)
        try gpx.close(all: true)

        let actual = try actual()
        XCTAssertFalse(actual.contains("<extensions>"))
        XCTAssertFalse(actual.contains("<cllocation:horizontalAccuracy>"))
    }

    func testEmptyVerticalAccuracy() throws {
        let gpx = try gpx()
        gpx.includingCllocation = true
        var location = [String: String]()
        location["latitude"] = "1"
        location["longitude"] = "2"
        location["verticalAccuracy"] = ""
        try gpx.writeLocation(location)
        try gpx.close(all: true)

        let actual = try actual()
        XCTAssertFalse(actual.contains("<extensions>"))
        XCTAssertFalse(actual.contains("<cllocation:verticalAccuracy>"))
    }

    func testValidVerticalAccuracyWithCllocation() throws {
        let gpx = try gpx()
        gpx.includingCllocation = true
        var location = [String: String]()
        location["latitude"] = "1"
        location["longitude"] = "2"
        location["verticalAccuracy"] = "3"
        try gpx.writeLocation(location)
        try gpx.close(all: true)

        let actual = try actual()
        XCTAssert(actual.contains("<extensions>"))
        XCTAssert(actual.contains("<cllocation:verticalAccuracy>3</cllocation:verticalAccuracy>"))
    }

    func testValidVerticalAccuracyWithoutCllocation() throws {
        let gpx = try gpx()
        gpx.includingCllocation = false
        var location = [String: String]()
        location["latitude"] = "1"
        location["longitude"] = "2"
        location["verticalAccuracy"] = "3"
        try gpx.writeLocation(location)
        try gpx.close(all: true)

        let actual = try actual()
        XCTAssertFalse(actual.contains("<extensions>"))
        XCTAssertFalse(actual.contains("<cllocation:verticalAccuracy>"))
    }

    func testEmptySpeedAccuracy() throws {
        let gpx = try gpx()
        gpx.includingCllocation = true
        var location = [String: String]()
        location["latitude"] = "1"
        location["longitude"] = "2"
        location["speedAccuracy"] = ""
        try gpx.writeLocation(location)
        try gpx.close(all: true)

        let actual = try actual()
        XCTAssertFalse(actual.contains("<extensions>"))
        XCTAssertFalse(actual.contains("<cllocation:speedAccuracy>"))
    }

    func testValidSpeedAccuracyWithCllocation() throws {
        let gpx = try gpx()
        gpx.includingCllocation = true
        var location = [String: String]()
        location["latitude"] = "1"
        location["longitude"] = "2"
        location["speedAccuracy"] = "3"
        try gpx.writeLocation(location)
        try gpx.close(all: true)

        let actual = try actual()
        XCTAssert(actual.contains("<extensions>"))
        XCTAssert(actual.contains("<cllocation:speedAccuracy>3</cllocation:speedAccuracy>"))
    }

    func testValidSpeedAccuracyWithoutCllocation() throws {
        let gpx = try gpx()
        gpx.includingCllocation = false
        var location = [String: String]()
        location["latitude"] = "1"
        location["longitude"] = "2"
        location["speedAccuracy"] = "3"
        try gpx.writeLocation(location)
        try gpx.close(all: true)

        let actual = try actual()
        XCTAssertFalse(actual.contains("<extensions>"))
        XCTAssertFalse(actual.contains("<cllocation:speedAccuracy>"))
    }

    func testEmptyCourseAccuracy() throws {
        let gpx = try gpx()
        gpx.includingCllocation = true
        var location = [String: String]()
        location["latitude"] = "1"
        location["longitude"] = "2"
        location["courseAccuracy"] = ""
        try gpx.writeLocation(location)
        try gpx.close(all: true)

        let actual = try actual()
        XCTAssertFalse(actual.contains("<extensions>"))
        XCTAssertFalse(actual.contains("<cllocation:courseAccuracy>"))
    }

    func testValidCourseAccuracyWithCllocation() throws {
        let gpx = try gpx()
        gpx.includingCllocation = true
        var location = [String: String]()
        location["latitude"] = "1"
        location["longitude"] = "2"
        location["courseAccuracy"] = "3"
        try gpx.writeLocation(location)
        try gpx.close(all: true)

        let actual = try actual()
        XCTAssert(actual.contains("<extensions>"))
        XCTAssert(actual.contains("<cllocation:courseAccuracy>3</cllocation:courseAccuracy>"))
    }

    func testValidCourseAccuracyWithoutCllocation() throws {
        let gpx = try gpx()
        gpx.includingCllocation = false
        var location = [String: String]()
        location["latitude"] = "1"
        location["longitude"] = "2"
        location["courseAccuracy"] = "3"
        try gpx.writeLocation(location)
        try gpx.close(all: true)

        let actual = try actual()
        XCTAssertFalse(actual.contains("<extensions>"))
        XCTAssertFalse(actual.contains("<cllocation:courseAccuracy>"))
    }

    // Although convert() isn't in GPXWriter, test it here.
    func testConvertWithValidTime() throws {
        let csv = """
        time,latitude,longitude\r
        2021-06-22 06:10:15 +09:00,1,2\r\n
        """

        let url = FileManager.default.documentURL(of: "test.csv")
        FileManager.default.createFile(atPath: url.path, contents: Data(csv.utf8))
        try LocationLogger.convert("test.csv")

        let actual = try actual()
        XCTAssert(actual.contains("<time>2021-06-21T21:10:15Z</time>"))
    }

    func testConvertWithInvalidTime() throws {
        let csv = """
        time,latitude,longitude\r
        2021-06-22 06:10:15,1,2\r\n
        """

        let url = FileManager.default.documentURL(of: "test.csv")
        FileManager.default.createFile(atPath: url.path, contents: Data(csv.utf8))
        try LocationLogger.convert("test.csv")

        let actual = try actual()
        XCTAssertFalse(actual.contains("<time>"))
    }
}
