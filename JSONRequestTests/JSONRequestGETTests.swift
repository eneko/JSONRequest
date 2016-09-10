//
//  JSONRequestGETTests.swift
//  JSONRequest
//
//  Created by Eneko Alonso on 1/11/16.
//  Copyright © 2016 Hathway. All rights reserved.
//

import XCTest
import JSONRequest

class JSONRequestGETTests: XCTestCase {

    let goodUrl = "http://httpbin.org/get"
    let badUrl = "httpppp://httpbin.org/get"
    let params: JSONObject = ["hello": "world"]

    func testSimple() throws {
        let request = JSONRequest()
        let data = try request.get(url: goodUrl, queryParams: params)
        XCTAssertNotNil(data)
        let object = data as? JSONObject
        XCTAssertNotNil(object?["args"])
        XCTAssertEqual((object?["args"] as? JSONObject)?["hello"] as? String, "world")
        XCTAssertEqual(request.httpResponse?.statusCode, 200)
    }

    func testDictionaryValue() throws {
        let result = try JSONRequest.get(url: goodUrl, queryParams: params)
        let dict = result as? [String: Any]
        XCTAssertEqual((dict?["args"] as? JSONObject)?["hello"] as? String, "world")
    }

    func testArrayValue() throws {
        let result = try JSONRequest.get(url: goodUrl, queryParams: params)
        let array = result as? [Any]
        XCTAssertEqual(array?.count, 0)
    }

    func testFailing() {
        let result = try? JSONRequest.get(url: badUrl, queryParams: params)
        XCTAssertNil(result)
    }

    func testAsync() {
        let expectation = self.expectation(description: "async")
        JSONRequest.get(url: goodUrl) { (result) in
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
        JSONRequest.get(url: badUrl) { (result) in
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
