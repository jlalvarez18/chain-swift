//
//  MockHSMAPI.swift
//  Chain-Swift
//
//  Created by Juan Alvarez on 8/20/17.
//
//

import Foundation
import JSON
import HTTP

struct HSMKey: NodeInitializable {
    // User specified, unique identifier of the key.
    let alias: String
    
    // Hex-encoded string representation of the key.
    let xpub: String
    
    init(node: Node) throws {
        self.alias = try node.get("alias")
        self.xpub = try node.get("xpub")
    }
}

class MockHSM {
    
    let client: Client
    let signerConnection: Connection
    
    lazy var keys: MockHSMKeysAPI = {
        return MockHSMKeysAPI(client: self.client)
    }()
    
    init(client: Client, signerConnection: Connection) {
        self.client = client
        self.signerConnection = signerConnection
    }
}

class MockHSMKeysAPI {
    let client: Client
    
    init(client: Client) {
        self.client = client
    }
    
    // Create a new MockHsm key.
    func create(alias: String) throws -> HSMKey {
        var body = JSON()
        try body.set("alias", alias)
        try body.set("clientToken", UUID().uuidString)
        
        let res = try self.client.request(path: "/mockhsm/create-key", body: body)
        
        guard let json = res.json else {
            throw ChainError(.badRequest, reason: "Missing JSON response")
        }
        
        return try HSMKey(node: json)
    }
    
    /**
     Get one page of MockHsm keys, optionally filtered to specified aliases.
     
     - parameter params: Filter and pagination information.
     - parameter aliases: List of requested aliases, max 200.
     - parameter pageSize: Number of items to return in result set.
     */
    func query(params: JSON) throws -> Page<HSMKey> {
        var p = params
        
        if let aliases: [String] = try params.get("aliases") {
            if aliases.count > 0 {
                try p.set("pageSize", aliases.count)
            }
        }
        
        return try self.client.query(path: "/mockhsm/list-keys", params: params)
    }
    
    func queryAll(params: JSON, itemBlock: (HSMKey) -> Bool, completion: (Error?) -> Void) throws {
        return try self.client.queryAll(path: "/mockhsm/list-keys", params: params, itemBlock: itemBlock, completion: completion)
    }
}
