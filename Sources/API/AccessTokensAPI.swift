//
//  AccessTokensAPI.swift
//  Chain-Swift
//
//  Created by Juan Alvarez on 8/20/17.
//
//

import Foundation
import Vapor

struct AccessToken: JSONInitializable {
    let id: String
    let token: String
    let createdAt: Date
    
    init(json: JSON) throws {
        self.id = try json.get("id")
        self.token = try json.get("token")
        
        let createdAtString: String = try json.get("createdAt")
        self.createdAt = Date(rfc3339: createdAtString)!
    }
}

class AccessTokensAPI {
    
    let client: Client
    
    init(client: Client) {
        self.client = client
    }
    
    func create(id: String) throws -> AccessToken {
        var params = JSON()
        try params.set("id", id)
        
        let res = try self.client.create(path: "/create-access-token", params: params, skipArray: true)
        
        guard let json = res.json else {
            throw Abort(.badRequest, reason: "Missing JSON response")
        }
        
        return try AccessToken(json: json)
    }
    
    func query(params: JSON) throws -> Page<AccessToken> {
        return try self.client.query(path: "/list-access-tokens", params: params)
    }
    
    func queryAll(params: JSON, itemBlock: (AccessToken) -> Bool, completion: (Error?) -> Void) throws {
        return try self.client.queryAll(path: "/list-access-tokens", params: params, itemBlock: itemBlock, completion: completion)
    }
    
    func delete(id: String) throws -> Response {
        var body = JSON()
        try body.set("id", id)
        
        return try self.client.request(path: "/delete-access-token", body: body)
    }
}
