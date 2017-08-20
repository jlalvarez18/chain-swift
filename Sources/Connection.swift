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

let blacklistAttributes = Set([
    "after",
    "asset_tags",
    "asset_definition",
    "account_tags",
    "next",
    "reference_data",
    "tags",
])

class Connection {
    
    // Chain Core URL
    let baseUrlString: String
    
    // Chain Core client token for API access.
    let token: String?
    
    // https.Agent used to provide TLS config.
    let agent: String?
    
    init(baseUrl: String, token: String?, agent: String?) {
        self.baseUrlString = baseUrl
        self.token = token
        self.agent = agent
    }
    
    func request(path: String, body: [String: Any] = [:]) throws {
        let bodyJSON = try snakeize(dict: body)
        let bodyData = try bodyJSON.makeBytes()
        
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
        
        let req = Request(method: .post, uri: url.absoluteString, headers: headers, body: .data(bodyData))
        
        print(req)
    }
}

fileprivate extension Connection {
    
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
