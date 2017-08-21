//
//  AssetsAPI.swift
//  Chain-Swift
//
//  Created by Juan Alvarez on 8/21/17.
//
//

import Foundation
import JSON
import Vapor

struct Asset: JSONInitializable {
    struct Key: JSONInitializable {
        let assetPubKey: String
        let rootXpub: String
        let assetDerivationPath: JSON
        
        init(json: JSON) throws {
            self.assetPubKey = try json.get("asset_pubkey")
            self.rootXpub = try json.get("root_xpub")
            self.assetDerivationPath = try json.get("asset_derivation_path")
        }
    }
    
    let id: String
    let alias: String
    let issuanceProgram: String
    let keys: [Key]
    let quorum: Int
    let defintion: JSON
    let tags: JSON
    
    init(json: JSON) throws {
        self.id = try json.get("id")
        self.alias = try json.get("alias")
        self.issuanceProgram = try json.get("issuanceProgram")
        self.keys = try json.get("keys")
        self.quorum = try json.get("quorum")
        self.defintion = try json.get("defintion")
        self.tags = try json.get("tags")
    }
}

struct AssetCreationRequest {
    let alias: String
    let rootXpubs: [HSMKey]
    let quorum: Int
    let tags: JSON
    let defintion: JSON
    
    func params() throws -> JSON {
        var params = JSON()
        
        try params.set("alias", self.alias)
        try params.set("rootXpubs", self.rootXpubs.map { $0.xpub })
        try params.set("quorum", self.quorum)
        try params.set("tags", self.tags)
        try params.set("defintion", self.defintion)
        
        return params
    }
}

class AssetsAPI {
    
    let client: Client
    
    init(client: Client) {
        self.client = client
    }
    
    func create(request: AssetCreationRequest) throws -> Asset {
        let params = try request.params()
        let res = try self.client.create(path: "/create-asset", params: params)
        
        guard let json = res.json else {
            throw Abort(.badRequest, reason: "Invalid JSON response")
        }
        
        return try Asset(json: json)
    }
    
    func createBatch(requests: [AssetCreationRequest]) throws -> BatchResponse {
        let params = try requests.map { try $0.params() }
        
        return try self.client.createBatch(path: "/create-asset", params: params)
    }
    
    func queryAll(params: JSON, itemBlock: (JSON) -> Bool, completion: (Error?) -> Void) throws {
        return try self.client.queryAll(owner: self, params: params, itemBlock: itemBlock, completion: completion)
    }
}

extension AssetsAPI: Queryable {
    
    func query(params: JSON) throws -> Page {
        return try self.client.query(owner: self, path: "/list-assets", params: params)
    }
}










