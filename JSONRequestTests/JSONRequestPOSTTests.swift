//
//  JSONRequestPOSTTests.swift
//  JSONRequest
//
//  Created by Eneko Alonso on 3/24/16.
//  Copyright © 2016 Hathway. All rights reserved.
//

import XCTest
import JSONRequest

class JSONRequestPOSTTests: XCTestCase {

    let goodUrl = "http://httpbin.org/post"
    let badUrl = "httpppp://httpbin.org/post"
    let params: JSONObject = ["hello": "world"]
    let payload: Any = ["hi": "there"]

    func testSimple() throws {
        let request = JSONRequest()
        let data = try request.post(url: goodUrl, queryParams: params, payload: payload)
        XCTAssertNotNil(data)
        let object = data as? JSONObject
        XCTAssertNotNil(object?["args"])
        XCTAssertEqual((object?["args"] as? JSONObject)?["hello"] as? String, "world")
        XCTAssertNotNil(object?["json"])
        XCTAssertEqual((object?["json"] as? JSONObject)?["hi"] as? String, "there")
        XCTAssertEqual(request.httpResponse?.statusCode, 200)
    }

    func testDictionaryValue() throws {
        let result = try JSONRequest.post(url: goodUrl, payload: payload)
        let dict = result as? [String: Any]
        XCTAssertEqual((dict?["json"] as? JSONObject)?["hi"] as? String, "there")
    }

    func testArrayValue() throws {
        let result = try JSONRequest.post(url: goodUrl, payload: payload)
        let array = result as? [Any]
        XCTAssertEqual(array?.count, 0)
    }

    func testFailing() throws {
        let result = try? JSONRequest.post(url: badUrl, payload: payload)
        XCTAssertNil(result)
    }

    func testAsync() {
        let expectation = self.expectation(description: "async")
        JSONRequest.post(url: goodUrl) { (result) in
            XCTAssertNil(result.error)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 15) { error in
            if error != nil {
                XCTFail()
            }
        }
    }

    func testAsyncFail() {
        let expectation = self.expectation(description: "async")
        JSONRequest.post(url: badUrl) { (result) in
            XCTAssertNotNil(result.error)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 15) { error in
            if error != nil {
                XCTFail()
            }
        }
    }

}
