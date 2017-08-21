//
//  AccessTokensAPI.swift
//  Chain-Swift
//
//  Created by Juan Alvarez on 8/20/17.
//
//

import Foundation
import Vapor

struct AccessToken {
    let id: String
    let token: String
    let createdAt: Date
    let type: String // DEPRECATED. Do not use in 1.2 or later. Either 'client' or 'network'.
    
    init(json: JSON) throws {
        self.id = try json.get("id")
        self.token = try json.get("token")
        
        let createdAtString: String = try json.get("createdAt")
        
        self.createdAt = Date(rfc3339: createdAtString)!
        self.type = try json.get("type")
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
    
    func queryAll(params: JSON, itemBlock: (JSON) -> Bool, completion: (Error?) -> Void) throws {
        return try self.client.queryAll(owner: self, params: params, itemBlock: itemBlock, completion: completion)
    }
    
    func delete(id: String) throws -> Response {
        var body = JSON()
        try body.set("id", id)
        
        return try self.client.request(path: "/delete-access-token", body: body)
    }
}

extension AccessTokensAPI: Queryable {
   
    func query(params: JSON) throws -> Page {
        return try self.client.query(owner: self, path: "/list-access-tokens", params: params)
    }
}
