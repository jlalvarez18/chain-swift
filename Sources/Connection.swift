//
//  Connection.swift
//  Chain-Swift
//
//  Created by Juan Alvarez on 8/19/17.
//
//

import Foundation

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
    let baseUrl: String
    
    // Chain Core client token for API access.
    let token: String
    
    // https.Agent used to provide TLS config.
    let agent: String
    
    init(baseUrl: String, token: String = "", agent: String) {
        self.baseUrl = baseUrl
        self.token = token
        self.agent = agent
    }
    
    func request(path: String, body: [String: Any] = [:]) {
        
    }
}

fileprivate extension Connection {
    
    func snakeize(dict: [String: Any]) {
        var newDict: [String: Any] = [:]
        
        for (key, value) in dict {
            // Skip all-caps keys
            if key.isAllCaps() {
                continue
            }
            
            
        }
    }
}
