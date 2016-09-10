//
//  JSONRequestTests.swift
//  JSONRequestTests
//
//  Created by Eneko Alonso on 9/26/14.
//  Copyright (c) 2014 Hathway. All rights reserved.
//

import XCTest
@testable import JSONRequest

class JSONRequestTests: XCTestCase {

    func testHTTPRequest() {
        let jsonRequest = JSONRequest()
        jsonRequest.updateRequest(method: .GET, url: "")
        XCTAssertEqual(jsonRequest.httpRequest.httpMethod, "GET")
    }

    func testCreateBadURL() {
        let jsonRequest = JSONRequest()
        let url = jsonRequest.createURL(urlString: "bad url", queryParams: nil)
        XCTAssertNil(url)
    }

    func testCreateEmptyURL() {
        let jsonRequest = JSONRequest()
        let url = jsonRequest.createURL(urlString: "", queryParams: nil)
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.absoluteString, "")
    }

    func testCreateURL() {
        let jsonRequest = JSONRequest()
        let url = jsonRequest.createURL(urlString: "http://httpbin.org",
                                        queryParams: nil)
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.absoluteString, "http://httpbin.org")
    }

    func testCreateURLWithParam() {
        let jsonRequest = JSONRequest()
        let url = jsonRequest.createURL(urlString: "http://httpbin.org",
                                        queryParams: ["q": "JSONRequest"])
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.absoluteString, "http://httpbin.org?q=JSONRequest")
    }

    func testCreateURLWithParams() {
        let jsonRequest = JSONRequest()
        let params: [String: AnyObject] = [
            "aaaa": 1 as AnyObject,
            "bbbb": "string" as AnyObject,
            "cccc": 2.2 as AnyObject
        ]
        let url = jsonRequest.createURL(urlString: "http://httpbin.org", queryParams: params)
        XCTAssertNotNil(url)
        XCTAssertNotNil(url?.absoluteString)
        XCTAssert(url?.absoluteString.contains("aaaa=1") ?? false)
        XCTAssert(url?.absoluteString.contains("bbbb=string") ?? false)
        XCTAssert(url?.absoluteString.contains("cccc=2.2") ?? false)
    }

    func testCreateURLWithNilParams() {
        let jsonRequest = JSONRequest()
        let params: JSONObject = [
            "aaaa": 1,
            "bbbb": "string",
            "cccc": 5.5
        ]
        let url = jsonRequest.createURL(urlString: "http://httpbin.org", queryParams: params)
        XCTAssertNotNil(url)
        XCTAssertNotNil(url?.absoluteString)
        XCTAssertEqual(url?.absoluteString.contains("aaaa=1"), true)
        XCTAssertEqual(url?.absoluteString.contains("bbbb=string"), true)
        XCTAssertEqual(url?.absoluteString.contains("cccc=5.5"), true)
    }

    func testCreateURLWithUrlParams() {
        let jsonRequest = JSONRequest()
        let url = jsonRequest.createURL(urlString: "http://httpbin.org?aaaa=1&bbbb=string&cccc=2.2",
                                        queryParams: nil)
        XCTAssertNotNil(url)
        XCTAssertNotNil(url?.absoluteString)
        XCTAssert(url?.absoluteString.contains("aaaa=1") ?? false)
        XCTAssert(url?.absoluteString.contains("bbbb=string") ?? false)
        XCTAssert(url?.absoluteString.contains("cccc=2.2") ?? false)
    }

    func testCreateURLWithUrlAndQueryParams() {
        let jsonRequest = JSONRequest()
        let params = [
            "aaaa": 1,
            "bbbb": "string",
            "cccc": 2.2
        ] as [String : Any]
        let url = jsonRequest.createURL(urlString: "http://httpbin.org?aaaa=1",
                                        queryParams: params)
        XCTAssertNotNil(url)
        XCTAssertNotNil(url?.absoluteString)
        XCTAssert(url?.absoluteString.contains("aaaa=1") ?? false)
        XCTAssertEqual(url?.absoluteString.components(separatedBy: "aaaa=1").count, 3)
        XCTAssert(url?.absoluteString.contains("bbbb=string") ?? false)
        XCTAssert(url?.absoluteString.contains("cccc=2.2") ?? false)
    }

    func testParseNilResponse() {
        let request = JSONRequest()
        let result = request.parse(data: nil, response: nil)
        switch result {
        case .failure(let error, let response, let body):
//            XCTAssertEqual(error, JSONError.nonHTTPResponse)
            XCTAssertNil(response)
            XCTAssertNil(body)
        case .success:
            XCTFail("Should always fail")
        }
    }

    func testParseNilResponseWithData() {
        let request = JSONRequest()
        let result = request.parse(data: Data(), response: nil)
        switch result {
        case .failure(let error, let response, let body):
//            XCTAssertEqual(error, JSONError.nonHTTPResponse)
            XCTAssertNil(response)
            XCTAssertNil(body)
        case .success:
            XCTFail("Should always fail")
        }
    }

    func testParseResponseWithNilData() {
        let request = JSONRequest()
        let response = HTTPURLResponse(url: URL(string: "http://httpbin.org")!,
                                         statusCode: 200,
                                         httpVersion: nil, headerFields: nil)
        let result = request.parse(data: nil, response: response)
        switch result {
        case .failure:
            XCTFail("Should not fail")
        case .success:
            XCTAssert(true)
        }
    }

//    func testParseResponseWithInvalidJSON() {
//        let request = JSONRequest()
//        let response = HTTPURLResponse(url: URL(string: "http://httpbin.org")!,
//                                         statusCode: 200,
//                                         httpVersion: nil, headerFields: nil)
//        let result = request.parseResponse(binaryData(), response: response)
//        switch result {
//        case .success:
//            XCTFail("Should have failed")
//        case .failure(let error, _, _):
//            XCTAssertEqual(error, JSONError.responseDeserialization)
//        }
//    }

    func testHttpRequestGetter() {
        let request = JSONRequest()
        XCTAssertNotNil(request.httpRequest)
    }

    func testPayload() {
        let payload = ["Hello": "world"]
        let request = JSONRequest()
        request.updateRequest(payload: payload)
        XCTAssertNotNil(request.httpRequest.httpBody)
    }

//    func testInvalidPayload() {
//        let payload = binaryData()
//        let request = JSONRequest()
//        request.updateRequestPayload(payload)
//        XCTAssertNil(request.httpRequest?.httpBody)
//    }

    func testBodyStringFromData() {
        let data = "Hello world".data(using: String.Encoding.utf8)
        XCTAssertEqual(JSONRequest().body(fromData: data), "Hello world")
    }

    func testUpdateRequestHeaders() {
        let headers: JSONObject = ["User-Agent": "XCTest"]
        let request = JSONRequest()
        request.updateRequest(headers: headers)
        XCTAssertEqual(request.httpRequest.allHTTPHeaderFields?["User-Agent"], "XCTest")
    }

//    fileprivate func binaryData() -> Data {
//        var int = 42
//        return Data(bytes: UnsafePointer<UInt8>(&int), count: 32)
//    }

}
