import XCTest
@testable import JSONRequest

class JSONRequestTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(JSONRequest().text, "Hello, World!")
    }


    static var allTests : [(String, (JSONRequestTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
