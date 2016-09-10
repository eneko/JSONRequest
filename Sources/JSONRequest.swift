//
//  JSONRequest.swift
//  JSONRequest
//
//  Created by Eneko Alonso on 9/12/14.
//  Copyright (c) 2014 Hathway. All rights reserved.
//

import Foundation
import SystemConfiguration

public typealias JSONObject = Dictionary<String, Any>

public enum JSONError: Error {
    case invalidURL
    case payloadSerialization

    case noInternetConnection
    case requestFailed(error: Error)

    case nonHTTPResponse
    case responseDeserialization

    case unknownError
}

public enum JSONResult {
    case success(data: Any?, response: HTTPURLResponse)
    case failure(error: JSONError, response: HTTPURLResponse?, body: String?)
}

public extension JSONResult {

    public var data: Any? {
        switch self {
        case .success(let data, _):
            return data
        case .failure:
            return nil
        }
    }

    public var arrayValue: [Any] {
        return data as? [Any] ?? []
    }

    public var dictionaryValue: [String: Any] {
        return data as? [String: Any] ?? [:]
    }

    public var httpResponse: HTTPURLResponse? {
        switch self {
        case .success(_, let response):
            return response
        case .failure(_, let response, _):
            return response
        }
    }

    public var error: Error? {
        switch self {
        case .success:
            return nil
        case .failure(let error, _, _):
            return error
        }
    }

}

open class JSONRequest {

    /**
     User Agent configuration for all requests
     */
    open static var userAgent: String?

    /**
     Maximum time in seconds for connection to the server to be established.
     */
    open static var requestTimeout = 30.0

    /**
     Maximum time in seconds for transmission to complete after connection has
     been established.
     */
    open static var resourceTimeout = 30.0

    /**
     Debug log configuration callback for tracing request information
     */
    open static var log: ((String) -> Void)?


    open var httpRequest: NSMutableURLRequest
    open var httpResponse: HTTPURLResponse?

    public init() {
        httpRequest = NSMutableURLRequest()
    }

    // MARK: Business logic

    func submitAsyncRequest(method: JSONRequestHttpVerb, url: String,
                            queryParams: JSONObject? = nil, payload: Any? = nil,
                            headers: JSONObject? = nil, complete: @escaping (JSONResult) -> Void) {
        if isConnectedToNetwork() == false {
            let error = JSONError.noInternetConnection
            complete(.failure(error: error, response: nil, body: nil))
            return
        }

        updateRequest(method: method, url: url, queryParams: queryParams)
        updateRequest(headers: headers)
        updateRequest(payload: payload)

        let start = Date()
        let session = networkSession()
        let task = session.dataTask(with: httpRequest as URLRequest) { (data, response, error) in
            let elapsed = -start.timeIntervalSinceNow
            self.httpResponse = response as? HTTPURLResponse
            self.traceResponse(elapsed: elapsed, responseData: data,
                               httpResponse: self.httpResponse,
                               error: error as NSError?)
            if let error = error {
                let result = JSONResult.failure(error: JSONError.requestFailed(error: error),
                                                response: response as? HTTPURLResponse,
                                                body: self.body(fromData: data))
                complete(result)
                return
            }
            let result = self.parse(data: data, response: response)
            complete(result)
        }
        trace(task: task)
        task.resume()
    }

    func networkSession() -> URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = JSONRequest.requestTimeout
        config.timeoutIntervalForResource = JSONRequest.resourceTimeout
        if let userAgent = JSONRequest.userAgent {
            config.httpAdditionalHeaders = ["User-Agent": userAgent]
        }
        return URLSession(configuration: config)
    }

    func submitSyncRequest(method: JSONRequestHttpVerb, url: String,
                           queryParams: JSONObject? = nil,
                           payload: Any? = nil,
                           headers: JSONObject? = nil) throws -> Any? {

        let semaphore = DispatchSemaphore(value: 0)
        var requestResult: JSONResult = JSONResult.failure(error: JSONError.unknownError,
                                                           response: nil, body: nil)

        submitAsyncRequest(method: method, url: url, queryParams: queryParams,
                           payload: payload, headers: headers) { result in
                            requestResult = result
                            semaphore.signal()
        }

        // Wait for the request to complete
        while semaphore.wait(timeout: DispatchTime.now()) == .timedOut {
            let intervalDate = Date(timeIntervalSinceNow: 0.01) // 10 milliseconds
            RunLoop.current.run(mode: RunLoopMode.defaultRunLoopMode, before: intervalDate)
        }

        switch requestResult {
        case .failure(let error, _, _):
            throw error
        case .success(let data, _):
            return data
        }
    }

    func updateRequest(method: JSONRequestHttpVerb, url: String,
                       queryParams: JSONObject? = nil) {
        httpRequest.url = createURL(urlString: url, queryParams: queryParams)
        httpRequest.httpMethod = method.rawValue
    }

    func updateRequest(headers: JSONObject?) {
        httpRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        httpRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        if let headers = headers {
            for (headerName, headerValue) in headers {
                httpRequest.setValue(String(describing: headerValue),
                                     forHTTPHeaderField: headerName)
            }
        }
    }

    func updateRequest(payload: Any?) {
        guard let payload = payload else {
            return
        }
        httpRequest.httpBody = objectToJSON(object: payload)
    }

    func createURL(urlString: String, queryParams: JSONObject?) -> URL? {
        var components = URLComponents(string: urlString)
        if queryParams != nil {
            if components?.queryItems == nil {
                components?.queryItems = []
            }
            for (key, value) in queryParams! {
                let item = URLQueryItem(name: key, value: String(describing: value))
                components?.queryItems?.append(item)
            }
        }
        return components?.url
    }

    func parse(data: Data?, response: URLResponse?) -> JSONResult {
        guard let httpResponse = response as? HTTPURLResponse else {
            return JSONResult.failure(error: JSONError.nonHTTPResponse, response: nil, body: nil)
        }
        guard let data = data, data.count > 0 else {
            return JSONResult.success(data: nil, response: httpResponse)
        }
        guard let json = JSONToObject(data: data) else {
            return JSONResult.failure(error: JSONError.responseDeserialization,
                                      response: httpResponse,
                                      body: dataToUTFString(data: data))
        }
        return JSONResult.success(data: json, response: httpResponse)
    }

    func body(fromData data: Data?) -> String? {
        guard let data = data else {
            return nil
        }
        return String(data: data, encoding: String.Encoding.utf8)
    }

    open func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)

        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        guard let reachability = defaultRouteReachability else {
            return false
        }

        var flags: SCNetworkReachabilityFlags = []
        SCNetworkReachabilityGetFlags(reachability, &flags)
        if flags.isEmpty {
            return false
        }

        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)

        return isReachable && !needsConnection
    }


    fileprivate func trace(task: URLSessionDataTask) {
        guard let log = JSONRequest.log else {
            return
        }

        log(">>>>>>>>>> JSON Request >>>>>>>>>>")
        if let method = task.currentRequest?.httpMethod {
            log("HTTP Method: \(method)")
        }
        if let url = task.currentRequest?.url?.absoluteString {
            log("Url: \(url)")
        }
        if let headers = task.currentRequest?.allHTTPHeaderFields {
            log("Headers: \(objectToJSONString(object: headers as Any, pretty: true))")
        }
        if let payload = task.currentRequest?.httpBody,
            let body = String(data: payload, encoding: String.Encoding.utf8) {
            log("Payload: \(body)")
        }
    }

    fileprivate func traceResponse(elapsed: TimeInterval, responseData: Data?,
                                   httpResponse: HTTPURLResponse?, error: NSError?) {
        guard let log = JSONRequest.log else {
            return
        }

        log("<<<<<<<<<< JSON Response <<<<<<<<<<")
        log("Time Elapsed: \(elapsed)")
        if let statusCode = httpResponse?.statusCode {
            log("Status Code: \(statusCode)")
        }
        if let headers = httpResponse?.allHeaderFields {
            log("Headers: \(objectToJSONString(object: headers as Any, pretty: true))")
        }
        if let data = responseData, let body = JSONToObject(data: data) {
            log("Body: \(objectToJSONString(object: body, pretty: true))")
        }
        if let errorString = error?.localizedDescription {
            log("Error: \(errorString)")
        }
    }

    fileprivate func JSONToObject(data: Data) -> Any? {
        return try? JSONSerialization.jsonObject(with: data, options: [.allowFragments])
    }

    fileprivate func objectToJSON(object: Any, pretty: Bool = false) -> Data? {
        if JSONSerialization.isValidJSONObject(object) {
            let options = pretty ? JSONSerialization.WritingOptions.prettyPrinted : []
            return try? JSONSerialization.data(withJSONObject: object, options: options)
        }
        return nil
    }

    fileprivate func objectToJSONString(object: Any, pretty: Bool) -> String {
        if let data = objectToJSON(object: object, pretty: pretty) {
            return dataToUTFString(data: data)
        }
        return ""
    }

    fileprivate func dataToUTFString(data: Data) -> String {
        return String(data: data, encoding: String.Encoding.utf8) ?? ""
    }

}
