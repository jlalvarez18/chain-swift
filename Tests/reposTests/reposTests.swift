import XCTest
@testable import Chain_Swift

class reposTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(repos().text, "Hello, World!")
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}
