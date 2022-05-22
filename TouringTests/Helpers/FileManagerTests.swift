import XCTest
@testable import Touring

class FileManagerTests: XCTestCase {
    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }

    func testDocumentURL() throws {
        let baseurl = FileManager.default.documentURL()
        XCTAssert(baseurl.path.hasSuffix("/Documents"))

        XCTAssertEqual(FileManager.default.documentURL(of: "foobar.txt").path,
                       baseurl.path + "/foobar.txt")
    }
}
