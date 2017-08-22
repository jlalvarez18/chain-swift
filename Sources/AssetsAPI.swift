//
//  AssetsAPI.swift
//  Chain-Swift
//
//  Created by Juan Alvarez on 8/21/17.
//
//

import Foundation
import JSON
import HTTP

struct Asset: NodeInitializable {
    struct Key: NodeInitializable {
        let assetPubKey: String
        let rootXpub: String
        let assetDerivationPath: JSON
        
        init(node: Node) throws {
            self.assetPubKey = try node.get("asset_pubkey")
            self.rootXpub = try node.get("root_xpub")
            self.assetDerivationPath = try node.get("asset_derivation_path")
        }
    }
    
    let id: String
    let alias: String
    let issuanceProgram: String
    let keys: [Key]
    let quorum: Int
    let defintion: JSON
    let tags: JSON
    let isLocal: Bool
    
    init(node: Node) throws {
        self.id = try node.get("id")
        self.alias = try node.get("alias")
        self.issuanceProgram = try node.get("issuance_program")
        self.keys = try node.get("keys")
        self.quorum = try node.get("quorum")
        self.defintion = try node.get("defintion")
        self.tags = try node.get("tags")
        self.isLocal = try node.get("is_local")
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
            throw ChainError(.badRequest, reason: "Missing JSON response")
        }
        
        return try Asset(node: json)
    }
    
    func createBatch(requests: [AssetCreationRequest]) throws -> BatchResponse {
        let params = try requests.map { try $0.params() }
        
        return try self.client.createBatch(path: "/create-asset", params: params)
    }
    
    func query(params: JSON) throws -> Page<Asset> {
        return try self.client.query(path: "/list-assets", params: params)
    }
    
    func queryAll(params: JSON, itemBlock: (Asset) -> Bool, completion: (Error?) -> Void) throws {
        return try self.client.queryAll(path: "/list-assets", params: params, itemBlock: itemBlock, completion: completion)
    }
}
