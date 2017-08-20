//
//  Connection.swift
//  Chain-Swift
//
//  Created by Juan Alvarez on 8/19/17.
//
//

import Foundation
import HTTP
import JSON
import Vapor

let blacklistAttributes = Set([
    "after",
    "asset_tags",
    "asset_definition",
    "account_tags",
    "next",
    "reference_data",
    "tags",
])

extension HeaderKey {
    static public var chainRequestID: HeaderKey {
        return HeaderKey("Chain-Request-Id")
    }
}

class Connection {
    
    // Chain Core URL
    let baseUrlString: String
    
    // Chain Core client token for API access.
    let token: String?
    
    // https.Agent used to provide TLS config.
    let agent: String?
    
    var client: ClientFactoryProtocol?
    
    init(baseUrl: String, token: String?, agent: String?) {
        self.baseUrlString = baseUrl
        self.token = token
        self.agent = agent
    }
    
    func request(path: String, body: [String: Any] = [:]) throws -> ResponseRepresentable {
        guard let client = self.client else {
            throw Abort(.badRequest)
        }
        
        let bodyJSON = try snakeize(dict: body)
        
        var headers: [HeaderKey: String] = [
            HeaderKey.accept: "application/json",
            HeaderKey.contentType: "application/json",
        ]
        
        if let token = self.token, let tokenData = token.data(using: .utf8) {
            let tokenDataEncoded = tokenData.base64EncodedString()
            
            headers[.authorization] = "Basic \(tokenDataEncoded)"
        }
        
        if let agent = self.agent {
            headers[.userAgent] = agent
        }
        
        var url = URL(string: self.baseUrlString)!
        url = url.appendingPathComponent(path)
        
        let res = try client.post(url.absoluteString, headers, bodyJSON)
        
        guard let _ = res.headers[.chainRequestID] else {
            throw Abort(.badRequest, reason: "Chain-Request-Id header is missing. There may be an issue with your proxy or network configuration.")
        }
        
        if res.status == .noContent {
            return res
        }
        
        guard let json = res.json else {
            throw Abort(.badRequest, reason: "could not parse JSON response")
        }
        
        guard (res.status.statusCode/100) == 2 else {
            throw Abort(res.status)
        }
        
        // After processing the response, convert snakecased field names to
        // camelcase to match language conventions.
        return try camelize(json: json)
    }
}

fileprivate extension Connection {
    
    func camelize(json: JSON) throws -> JSON {
        return try camelize(data: json.wrapped)
    }
    
    func camelize(data: StructuredData) throws -> JSON {
        switch data {
        case .object(let dict):
            return try camelize(dict: dict)
        
        case .array(let a):
            let f = try a.map { (data) -> StructuredData in
                return try camelize(data: data).wrapped
            }
            
            return JSON(f)
            
        default:
            return JSON(data)
        }
    }
    
    func camelize(dict: [String: Any]) throws -> JSON {
        var json = JSON()
        
        for (key, value) in dict {
            let newKey = key.camelize()
            var newValue = value
            
            if !blacklistAttributes.contains(key) {
                if let valueDict = value as? [String: Any] {
                    newValue = try camelize(dict: valueDict)
                }
            }
            
            try json.set(newKey, newValue)
        }
        
        return json
    }
    
    func snakeize(dict: [String: Any]) throws -> JSON {
        var json = JSON()
        
        for (key, value) in dict {
            let newKey = key.snakeCased()
            var newValue = value
            
            // Skip all-caps keys
            if key.isAllCaps() {
                try json.set(newKey, newValue)
            } else {
                if !blacklistAttributes.contains(key) {
                    if let valueDict = value as? [String: Any] {
                        newValue = try snakeize(dict: valueDict)
                    }
                }
                
                try json.set(newKey, newValue)
            }
        }
        
        return json
    }
}
