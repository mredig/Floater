import XCTest
@testable import Floater

final class FloaterTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Floater().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
