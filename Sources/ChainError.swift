//
//  ChainError.swift
//  Chain-Swift
//
//  Created by Juan Alvarez on 8/21/17.
//
//

import Foundation
import HTTP
import JSON

public struct APIError: Error {
    
    enum ErrorType: String {
        case fetch = "FETCH"
        case connectivity = "CONNECTIVITY"
        case JSON = "JSON"
        case unauthorized = "UNAUTHORIZED"
        case notFound = "NOT_FOUND"
        case badRequest = "BAD_REQUEST"
        case serverError = "SERVER_ERROR"
        case noRequestId = "NO_REQUEST_ID"
        
        static func getType(response: Response) -> ErrorType {
            let errorType: APIError.ErrorType
            
            let status = response.status
            if status == .unauthorized {
                errorType = .unauthorized
            } else if status == .notFound {
                errorType = .notFound
            } else if (status.statusCode / 100 == 4) {
                errorType = .badRequest
            } else {
                errorType = .serverError
            }
            
            return errorType
        }
    }
    
    let type: ErrorType
    let message: String
    
    var code: String? // Unique identifier for the error.
    var requestId: String? // Unique identifier of the request to the server.
    var chainClientError: Bool = false
    var chainMessage: String?
    var detail: String? // Additional information about the error (possibly null).
    var properties: Node?
    var resp: Any?
    
    private init(type: ErrorType, message: String) {
        self.type = type
        self.message = message
    }
    
    static func create(type: ErrorType, message: String, props: Node = Node(nil)) throws -> APIError {
        var error: APIError
        
        if let body: Node = try props.get("body") {
            let requestId: String? = try body.get("requestId")
            error = try createBatchError(type: type, body: body, requestId: requestId)
        } else {
            error = APIError(type: type, message: message)
        }
        
        error.properties = props
        error.chainClientError = true
        
        return error
    }
    
    static func createBatchError(type: ErrorType, body: Node, requestId: String? = nil) throws -> APIError {
        let message = try formatErrorMessage(body: body, requestId: requestId)
        
        var error = APIError(type: type, message: message)
        error.code = try body.get("code")
        error.chainMessage = try body.get("message")
        error.detail = try body.get("detail")
        error.requestId = requestId
        error.resp = try body.get("resp")
        
        return error
    }
    
    static func createJSONError(response: Response) throws -> APIError {
        var props = Node(nil)
        try! props.set("response", response)
        try! props.set("status", response.status.statusCode)
        
        let msg = "Could not parse JSON response"
        let _error = try! APIError.create(type: .JSON, message: msg, props: props)
        
        return _error
    }
    
    static func isBatchError(body: JSON) throws -> Bool {
        let code: String? = try body.get("code")
        let stack: Any? = try body.get("stack")
        
        return (code != nil) && (stack == nil)
    }
    
    static func formatErrorMessage(body: Node, requestId: String?) throws -> String {
        var tokens: [String] = []
        
        if let code: String = try body.get("code") {
            tokens.append("Code: \(code)")
        }
        
        if let message: String = try body.get("message") {
            tokens.append("Message: \(message)")
        }
        
        if let detail: String = try body.get("detail") {
            tokens.append("Detail: \(detail)")
        }
        
        if let reqId = requestId {
            tokens.append("Request-ID: \(reqId)")
        }
        
        return tokens.joined(separator: " ")
    }
}






