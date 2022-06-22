import XCTest
@testable import Touring

class DestinationSetTests: XCTestCase {
    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }

    func testEmptyDestination() throws {
        let destset = DestinationSet()
        XCTAssert(destset.destinations.isEmpty)
        XCTAssertNil(destset.targetIndex)
        XCTAssertNil(destset.target)
    }

    func testAddDestinations() throws {
        let dests = [Destination(), Destination()]
        let destset = DestinationSet()

        // 1st
        destset.destinations += [dests[0]]
        XCTAssertEqual(destset.destinations, [dests[0]])
        XCTAssertEqual(destset.targetIndex, 0)
        XCTAssertEqual(destset.target, dests[0])

        // 2nd shouldn't change the target.
        destset.destinations += [dests[1]]
        XCTAssertEqual(destset.destinations, dests)
        XCTAssertEqual(destset.targetIndex, 0)
        XCTAssertEqual(destset.target, dests[0])
    }

    func testRemoveAllDestinations() throws {
        let destset = DestinationSet()
        destset.destinations = [Destination(), Destination()]

        destset.destinations.removeAll()
        XCTAssert(destset.destinations.isEmpty)
        XCTAssertNil(destset.targetIndex)
        XCTAssertNil(destset.target)
    }

    func testTargetWithRemovingLastDestination() throws {
        let dest0 = Destination()
        let dest1 = Destination()
        let dest2 = Destination()
        let destset = DestinationSet()
        destset.destinations = [dest0, dest1, dest2]
        destset.targetIndex = 2

        destset.destinations.remove(at: 2)
        XCTAssertEqual(destset.destinations, [dest0, dest1])
        XCTAssertEqual(destset.targetIndex, 1)
        XCTAssertEqual(destset.target, dest1)
    }

    func testTargetWithRemovingPreviousDestination() throws {
        let dest0 = Destination()
        let dest1 = Destination()
        let dest2 = Destination()
        let destset = DestinationSet()
        destset.destinations = [dest0, dest1, dest2]
        destset.targetIndex = 1

        destset.destinations.remove(at: 0)
        XCTAssertEqual(destset.destinations, [dest1, dest2])
        XCTAssertEqual(destset.targetIndex, 0)
        XCTAssertEqual(destset.target, dest1)
    }

    func testTargetWithRemovingTargetDestination() throws {
        let dest0 = Destination()
        let dest1 = Destination()
        let dest2 = Destination()
        let destset = DestinationSet()
        destset.destinations = [dest0, dest1, dest2]
        destset.targetIndex = 1

        destset.destinations.remove(at: 1)
        XCTAssertEqual(destset.destinations, [dest0, dest2])
        XCTAssertEqual(destset.targetIndex, 1)
        XCTAssertEqual(destset.target, dest2)
    }

    func testTargetWithRemovingLaterDestination() throws {
        let dest0 = Destination()
        let dest1 = Destination()
        let dest2 = Destination()
        let destset = DestinationSet()
        destset.destinations = [dest0, dest1, dest2]
        destset.targetIndex = 1

        destset.destinations.remove(at: 2)
        XCTAssertEqual(destset.destinations, [dest0, dest1])
        XCTAssertEqual(destset.targetIndex, 1)
        XCTAssertEqual(destset.target, dest1)
    }

    func testTargetWithSwappingDestinations() throws {
        let dest0 = Destination()
        let dest1 = Destination()
        let dest2 = Destination()
        let destset = DestinationSet()
        destset.destinations = [dest0, dest1, dest2]
        destset.targetIndex = 1

        destset.destinations.move(fromOffsets: [1], toOffset: 3)
        XCTAssertEqual(destset.destinations, [dest0, dest2, dest1])
        XCTAssertEqual(destset.targetIndex, 2)
        XCTAssertEqual(destset.target, dest1)
    }

    func testIsEmpty() throws {
        let destset = DestinationSet()

        XCTAssert(destset.isEmpty)
    }

    func testIsEmptyWithEmptyName() throws {
        let destset = DestinationSet()

        destset.name = ""
        XCTAssert(destset.isEmpty)
    }

    func testIsEmptyWithName() throws {
        let destset = DestinationSet()

        destset.name = "foo"
        XCTAssertFalse(destset.isEmpty)
    }

    func testIsEmptyWithDestination() throws {
        let destset = DestinationSet()

        destset.destinations = [Destination()]
        XCTAssertFalse(destset.isEmpty)
    }

    func testRouteSummaryWithZeroDestinations() throws {
        let destset = DestinationSet()

        XCTAssertNil(destset.routeSummary)
    }

    func testRouteSummaryWithNonameDestinations() throws {
        let destset = DestinationSet()

        destset.destinations = [Destination(), Destination(), Destination()]
        XCTAssertNil(destset.routeSummary)
    }

    func testRouteSummaryWithOneNamedDestinationAndOthers() throws {
        let destset = DestinationSet()

        destset.destinations = [Destination(), Destination(), Destination()]
        destset.destinations[1].title = "dest1"
        XCTAssertEqual(destset.routeSummary, "dest1")
    }

    func testRouteSummaryWithSomeNamedDestinationsAndOthers() throws {
        let destset = DestinationSet()

        destset.destinations = [Destination(), Destination(), Destination()]
        destset.destinations[0].title = "dest1"
        destset.destinations[2].title = "dest2"
        XCTAssertEqual(destset.routeSummary, "dest2\u{2190}dest1")
    }

    func testRouteSummaryWithNamedDestinations() throws {
        let destset = DestinationSet()

        destset.destinations = [Destination(), Destination(), Destination()]
        destset.destinations[0].title = "dest1"
        destset.destinations[1].title = "dest2"
        destset.destinations[2].title = "dest3"
        XCTAssertEqual(destset.routeSummary, "dest3\u{2190}dest2\u{2190}dest1")
    }

    func testGoForwardWithEmptyDestination() throws {
        let destset = DestinationSet()

        destset.goForward()
        XCTAssertNil(destset.targetIndex)
        XCTAssertNil(destset.target)
    }

    func testGoForwardWithSingleDestination() throws {
        let dests = [Destination()]

        let destset = DestinationSet()
        destset.destinations = dests

        destset.goForward()
        XCTAssertEqual(destset.targetIndex, 0)
        XCTAssertEqual(destset.target, dests[0])
    }

    func testGoForwardWithSomeDestinations() throws {
        let dests = [Destination(), Destination(), Destination()]

        let destset = DestinationSet()
        destset.destinations = dests

        destset.goForward()
        XCTAssertEqual(destset.targetIndex, 1)
        XCTAssertEqual(destset.target, dests[1])

        destset.goForward()
        XCTAssertEqual(destset.targetIndex, 2)
        XCTAssertEqual(destset.target, dests[2])

        destset.goForward()
        XCTAssertEqual(destset.targetIndex, 0)
        XCTAssertEqual(destset.target, dests[0])
    }

    func testGoBackwardWithEmptyDestination() throws {
        let destset = DestinationSet()

        destset.goBackward()
        XCTAssertNil(destset.targetIndex)
        XCTAssertNil(destset.target)
    }

    func testGoBackwardWithSingleDestination() throws {
        let dests = [Destination()]

        let destset = DestinationSet()
        destset.destinations = dests

        destset.goBackward()
        XCTAssertEqual(destset.targetIndex, 0)
        XCTAssertEqual(destset.target, dests[0])
    }

    func testGoBackwardWithSomeDestinations() throws {
        let dests = [Destination(), Destination(), Destination()]

        let destset = DestinationSet()
        destset.destinations = dests

        destset.goBackward()
        XCTAssertEqual(destset.targetIndex, 2)
        XCTAssertEqual(destset.target, dests[2])

        destset.goBackward()
        XCTAssertEqual(destset.targetIndex, 1)
        XCTAssertEqual(destset.target, dests[1])

        destset.goBackward()
        XCTAssertEqual(destset.targetIndex, 0)
        XCTAssertEqual(destset.target, dests[0])
    }

    func testDestinationsPublisherWithEmptyInitialValue() throws {
        let destset = DestinationSet()

        let expect = expectation(description: "")

        withExtendedLifetime(destset.destinationsPublisher.sink {
            if $0.isEmpty {
                expect.fulfill()
            }
        }) {
            waitForExpectations(timeout: 3)
        }
    }

    func testDestinationsPublisherWithNonEmptyInitialValue() throws {
        let destset = DestinationSet()
        let dests = [Destination()]
        destset.destinations = dests

        let expect = expectation(description: "")

        withExtendedLifetime(destset.destinationsPublisher.sink {
            if $0 == dests {
                expect.fulfill()
            }
        }) {
            waitForExpectations(timeout: 3)
        }
    }

    func testDestinationsPublisherWithAssigning() throws {
        let destset = DestinationSet()
        let dests = [Destination()]

        let expect = expectation(description: "")

        withExtendedLifetime(destset.destinationsPublisher.sink {
            if $0 == dests {
                expect.fulfill()
            }
        }) {
            destset.destinations = dests
            waitForExpectations(timeout: 3)
        }
    }

    func testDestinationsPublisherWithRemoving() throws {
        let destset = DestinationSet()
        destset.destinations = [Destination()]

        let expect = expectation(description: "")

        withExtendedLifetime(destset.destinationsPublisher.sink {
            if $0.isEmpty {
                expect.fulfill()
            }
        }) {
            destset.destinations.removeAll()
            waitForExpectations(timeout: 3)
        }
    }

    func testDestinationsPublisherWithModifyingAnotherVariable() throws {
        let destset = DestinationSet()
        let dests = [Destination()]

        let expect = expectation(description: "")

        withExtendedLifetime(destset.destinationsPublisher.sink {
            if $0 == dests {
                expect.fulfill()
            }
        }) {
            let destset2 = destset
            destset2.destinations = dests
            waitForExpectations(timeout: 3)
        }
    }

    func testTargetIndexPublisherWithInitialValue() throws {
        let destset = DestinationSet()
        destset.destinations = [Destination(), Destination()]
        destset.goForward()

        let expect = expectation(description: "")

        withExtendedLifetime(destset.targetIndexPublisher.sink {
            if $0 == 1 {
                expect.fulfill()
            }
        }) {
            waitForExpectations(timeout: 3)
        }
    }

    func testTargetIndexPublisher() throws {
        let destset = DestinationSet()
        destset.destinations = [Destination(), Destination()]

        let expect = expectation(description: "")

        withExtendedLifetime(destset.targetIndexPublisher.sink {
            if $0 == 1 {
                expect.fulfill()
            }
        }) {
            destset.goForward()
            waitForExpectations(timeout: 3)
        }
    }

    func testTargetIndexPublisherWithModifyingAnotherVariable() throws {
        let destset = DestinationSet()
        destset.destinations = [Destination(), Destination()]

        let expect = expectation(description: "")

        withExtendedLifetime(destset.targetIndexPublisher.sink {
            if $0 == 1 {
                expect.fulfill()
            }
        }) {
            let destset2 = destset
            destset2.goForward()
            waitForExpectations(timeout: 3)
        }
    }

    func testTargetPublisherWithInitialValue() throws {
        let dests = [Destination(), Destination()]
        let destset = DestinationSet()
        destset.destinations = dests
        destset.goForward()

        let expect = expectation(description: "")

        withExtendedLifetime(destset.targetPublisher.sink {
            if $0 == dests[1] {
                expect.fulfill()
            }
        }) {
            waitForExpectations(timeout: 3)
        }
    }

    func testTargetPublisher() throws {
        let dests = [Destination(), Destination()]
        let destset = DestinationSet()
        destset.destinations = dests

        let expect = expectation(description: "")

        withExtendedLifetime(destset.targetPublisher.sink {
            if $0 == dests[1] {
                expect.fulfill()
            }
        }) {
            destset.goForward()
            waitForExpectations(timeout: 3)
        }
    }

    func testTargetPublisherWithModifyingAnotherVariable() throws {
        let dests = [Destination(), Destination()]
        let destset = DestinationSet()
        destset.destinations = dests

        let expect = expectation(description: "")

        withExtendedLifetime(destset.targetPublisher.sink {
            if $0 == dests[1] {
                expect.fulfill()
            }
        }) {
            let destset2 = destset
            destset2.goForward()
            waitForExpectations(timeout: 3)
        }
    }

    func testCurrentWithInitialState() throws {
        XCTAssertNil(DestinationSet.current.name)
        XCTAssert(DestinationSet.current.destinations.isEmpty)
        XCTAssertNil(DestinationSet.current.targetIndex)
        XCTAssertNil(DestinationSet.current.target)
    }

    func testCurrentPublisher() throws {
        let destset = DestinationSet()

        let expect = expectation(description: "")

        withExtendedLifetime(DestinationSet.currentPublisher.sink {
            if $0 === destset {
                expect.fulfill()
            }
        }) {
            DestinationSet.current = destset
            waitForExpectations(timeout: 3)
        }
    }

    func testSaveAndLoadWithSingleDestinationSet() throws {
        let destset1 = DestinationSet()
        destset1.name = "destset1"
        destset1.destinations = [Destination(), Destination()]
        destset1.destinations[0].title = "dest1"
        destset1.destinations[0].coordinate.latitude = 1
        destset1.destinations[0].coordinate.longitude = 2
        destset1.destinations[1].title = "dest2"
        destset1.destinations[1].coordinate.latitude = 3
        destset1.destinations[1].coordinate.longitude = 4
        DestinationSet.current = destset1
        DestinationSet.others = []

        try? DestinationSet.saveAll()
        try? DestinationSet.loadAll()

        XCTAssertEqual(DestinationSet.current, destset1)
        XCTAssertEqual(DestinationSet.others, [])
    }

    func testSaveAndLoadWithTwoDestinationSets() throws {
        let destset1 = DestinationSet()
        destset1.name = "destset1"
        destset1.destinations = [Destination(), Destination()]
        destset1.destinations[0].title = "dest1"
        destset1.destinations[0].coordinate.latitude = 1
        destset1.destinations[0].coordinate.longitude = 2
        destset1.destinations[1].title = "dest2"
        destset1.destinations[1].coordinate.latitude = 3
        destset1.destinations[1].coordinate.longitude = 4

        let destset2 = DestinationSet()
        destset2.name = "destset2"
        destset2.destinations = [Destination(), Destination()]
        destset2.destinations[0].title = "dest2-1"
        destset2.destinations[0].coordinate.latitude = 5
        destset2.destinations[0].coordinate.longitude = 6
        destset2.destinations[1].title = "dest2-2"
        destset2.destinations[1].coordinate.latitude = 7
        destset2.destinations[1].coordinate.longitude = 8

        DestinationSet.current = destset1
        DestinationSet.others = [destset2]

        try? DestinationSet.saveAll()
        try? DestinationSet.loadAll()

        XCTAssertEqual(DestinationSet.current, destset1)
        XCTAssertEqual(DestinationSet.others, [destset2])
    }

    func testSelectAtWithSingleOthers() throws {
        let destset1 = DestinationSet()
        destset1.name = "destset1"

        let destset2 = DestinationSet()
        destset2.name = "destset2"

        DestinationSet.current = destset1
        DestinationSet.others = [destset2]

        DestinationSet.select(at: 0)
        XCTAssertEqual(DestinationSet.current, destset2)
        XCTAssertEqual(DestinationSet.others, [destset1])
    }

    func testSelectAtWithEmptyCurrentAndSingleOthers() throws {
        let destset1 = DestinationSet()

        let destset2 = DestinationSet()
        destset2.name = "destset2"

        DestinationSet.current = destset1
        DestinationSet.others = [destset2]

        DestinationSet.select(at: 0)
        XCTAssertEqual(DestinationSet.current, destset2)
        XCTAssertEqual(DestinationSet.others, [])
    }

    func testSelectAtWithSomeOthersAndSelectFirst() throws {
        let destset1 = DestinationSet()
        destset1.name = "destset1"
        let destset2 = DestinationSet()
        destset2.name = "destset2"
        let destset3 = DestinationSet()
        destset3.name = "destset3"
        let destset4 = DestinationSet()
        destset4.name = "destset4"

        DestinationSet.current = destset1
        DestinationSet.others = [destset2, destset3, destset4]

        DestinationSet.select(at: 0)
        XCTAssertEqual(DestinationSet.current, destset2)
        XCTAssertEqual(DestinationSet.others, [destset1, destset3, destset4])
    }

    func testSelectAtWithEmptyCurrentAndSomeOthersAndSelectFirst() throws {
        let destset1 = DestinationSet()
        let destset2 = DestinationSet()
        destset2.name = "destset2"
        let destset3 = DestinationSet()
        destset3.name = "destset3"
        let destset4 = DestinationSet()
        destset4.name = "destset4"

        DestinationSet.current = destset1
        DestinationSet.others = [destset2, destset3, destset4]

        DestinationSet.select(at: 0)
        XCTAssertEqual(DestinationSet.current, destset2)
        XCTAssertEqual(DestinationSet.others, [destset3, destset4])
    }

    func testSelectAtWithSomeOthersAndSelectMiddle() throws {
        let destset1 = DestinationSet()
        destset1.name = "destset1"
        let destset2 = DestinationSet()
        destset2.name = "destset2"
        let destset3 = DestinationSet()
        destset3.name = "destset3"
        let destset4 = DestinationSet()
        destset4.name = "destset4"

        DestinationSet.current = destset1
        DestinationSet.others = [destset2, destset3, destset4]

        DestinationSet.select(at: 1)
        XCTAssertEqual(DestinationSet.current, destset3)
        XCTAssertEqual(DestinationSet.others, [destset1, destset2, destset4])
    }

    func testSelectAtWithEmptyCurrentAndSomeOthersAndSelectMiddle() throws {
        let destset1 = DestinationSet()
        let destset2 = DestinationSet()
        destset2.name = "destset2"
        let destset3 = DestinationSet()
        destset3.name = "destset3"
        let destset4 = DestinationSet()
        destset4.name = "destset4"

        DestinationSet.current = destset1
        DestinationSet.others = [destset2, destset3, destset4]

        DestinationSet.select(at: 1)
        XCTAssertEqual(DestinationSet.current, destset3)
        XCTAssertEqual(DestinationSet.others, [destset2, destset4])
    }

    func testSelect() throws {
        let destset1 = DestinationSet()
        destset1.name = "destset1"
        let destset2 = DestinationSet()
        destset2.name = "destset2"
        let destset3 = DestinationSet()
        destset3.name = "destset3"
        let destset4 = DestinationSet()
        destset4.name = "destset4"

        DestinationSet.current = destset1
        DestinationSet.others = [destset2, destset3, destset4]

        XCTAssert(DestinationSet.select(destset3))
        XCTAssertEqual(DestinationSet.current, destset3)
        XCTAssertEqual(DestinationSet.others, [destset1, destset2, destset4])
    }

    func testSelectWithMissing() throws {
        let destset1 = DestinationSet()
        destset1.name = "destset1"
        let destset2 = DestinationSet()
        destset2.name = "destset2"
        let destset3 = DestinationSet()
        destset3.name = "destset3"
        let destset4 = DestinationSet()
        destset4.name = "destset4"

        DestinationSet.current = destset1
        DestinationSet.others = [destset2, destset3, destset4]

        let oldCurrent = DestinationSet.current
        let oldOthers = DestinationSet.others
        XCTAssertFalse(DestinationSet.select(DestinationSet()))
        XCTAssertEqual(DestinationSet.current, oldCurrent)
        XCTAssertEqual(DestinationSet.others, oldOthers)
    }
}

// Destination's == operator tests their identity, but XCTAssertEqual()
// should test their equality. So here we implement XCTAssertEqual() for
// Destination, DestinationSet, and their arrays.

func XCTAssertEqual<T: Destination>(
    _ expression1: @autoclosure () throws -> T,
    _ expression2: @autoclosure () throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath, line: UInt = #line)
rethrows {
    try XCTAssertEqual(expression1().title,
                       expression2().title,
                       message(), file: file, line: line)
    try XCTAssertEqual(expression1().coordinate.latitude,
                       expression2().coordinate.latitude,
                       message(), file: file, line: line)
    try XCTAssertEqual(expression1().coordinate.longitude,
                       expression2().coordinate.longitude,
                       message(), file: file, line: line)
}

func XCTAssertEqual<T: Destination>(
    _ expression1: @autoclosure () throws -> [T],
    _ expression2: @autoclosure () throws -> [T],
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath, line: UInt = #line)
rethrows {
    let dests1 = try expression1()
    let dests2 = try expression2()

    // Even if the two lengths differ, test their elements that can be
    // paired with.
    for i in 0..<max(dests1.count, dests2.count) {
        if i >= dests1.count {
            XCTFail(!message().isEmpty ? message() :
                        "\(dests1) is shorter than \(dests2)",
                    file: file, line: line)
            break
        }
        if i >= dests2.count {
            XCTFail(!message().isEmpty ? message() :
                        "\(dests1) is longer than \(dests2)",
                    file: file, line: line)
            break
        }
        XCTAssertEqual(dests1[i], dests2[i], message(), file: file, line: line)
    }
}

func XCTAssertEqual<T: DestinationSet>(
    _ expression1: @autoclosure () throws -> T,
    _ expression2: @autoclosure () throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath, line: UInt = #line)
rethrows {
    let destset1 = try expression1()
    let destset2 = try expression2()
    XCTAssertEqual(destset1.name, destset2.name, message(), file: file, line: line)
    XCTAssertEqual(destset1.destinations, destset2.destinations, message(), file: file, line: line)
}

func XCTAssertEqual<T: DestinationSet>(
    _ expression1: @autoclosure () throws -> [T],
    _ expression2: @autoclosure () throws -> [T],
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath, line: UInt = #line)
rethrows {
    let destsets1 = try expression1()
    let destsets2 = try expression2()

    // Even if the two lengths differ, test their elements that can be
    // paired with.
    for i in 0..<max(destsets1.count, destsets2.count) {
        if i >= destsets1.count {
            XCTFail(!message().isEmpty ? message() :
                        "\(destsets1) is shorter than \(destsets2)",
                    file: file, line: line)
            break
        }
        if i >= destsets2.count {
            XCTFail(!message().isEmpty ? message() :
                        "\(destsets1) is longer than \(destsets2)",
                    file: file, line: line)
            break
        }
        XCTAssertEqual(destsets1[i], destsets2[i], message(), file: file, line: line)
    }
}
