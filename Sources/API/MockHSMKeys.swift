//
//  MockHSMKeys.swift
//  Chain-Swift
//
//  Created by Juan Alvarez on 8/20/17.
//
//

import Foundation
import JSON
import HTTP
import Vapor

struct HSMKey {
    // User specified, unique identifier of the key.
    let alias: String
    
    // Hex-encoded string representation of the key.
    let xpub: String
    
    init(json: JSON) throws {
        self.alias = try json.get("alias")
        self.xpub = try json.get("xpub")
    }
}

class MockHSM {
    
    let client: Client
    let signerConnection: Connection
    
    init(client: Client, signerConnection: Connection) {
        self.client = client
        self.signerConnection = signerConnection
    }
    
    // Create a new MockHsm key.
    func create(alias: String) throws -> HSMKey {
        var body = JSON()
        try body.set("alias", alias)
        try body.set("clientToken", UUID().uuidString)
        
        let res = try self.client.request(path: "/mockhsm/create-key", body: body)
        
        guard let json = res.json else {
            throw Abort(.badRequest)
        }
        
        return try HSMKey(json: json)
    }
    
    func queryAll(params: JSON, itemBlock: (JSON) -> Bool, completion: (Error?) -> Void) throws {
        return try self.client.queryAll(owner: self, params: params, itemBlock: itemBlock, completion: completion)
    }
}

extension MockHSM: Queryable {
    
    /**
     Get one page of MockHsm keys, optionally filtered to specified aliases.
     
     - parameter params: Filter and pagination information.
     - parameter aliases: List of requested aliases, max 200.
     - parameter pageSize: Number of items to return in result set.
     */
    func query(params: JSON) throws -> Page {
        var p = params
        
        if let aliases: [String] = try params.get("aliases") {
            if aliases.count > 0 {
                try p.set("pageSize", aliases.count)
            }
        }
     
        return try self.client.query(owner: self, path: "/mockhsm/list-keys", params: params)
    }
}
