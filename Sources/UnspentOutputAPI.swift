//
//  UnspentOutputAPI.swift
//  Chain-Swift
//
//  Created by Juan Alvarez on 8/21/17.
//
//

import Foundation
import JSON

struct UnspentOutput: NodeInitializable {
    let id: String
    let type: String // Possible values are "control" and "retire".
    let purpose: String // // The purpose of the output. Possible values are "receive" and "change".
    let transactionId: String
    let position: String
    
    let assetId: String
    let assetAlias: String?
    let assetDefinition: JSON?
    let assetTags: JSON?
    let assetIsLocal: Bool
    
    let amount: Int
    
    let accountId: String?
    let accountAlias: String?
    let accountTags: String?
    
    let controlProgram: String
    let referenceData: JSON?
    
    let isLocal: Bool
    
    init(node: Node) throws {
        self.id = try node.get("id")
        self.type = try node.get("type")
        self.purpose = try node.get("purpose")
        self.transactionId = try node.get("transaction_id")
        self.position = try node.get("position")
        self.assetId = try node.get("asset_id")
        self.assetAlias = try node.get("asset_alias")
        self.assetDefinition = try node.get("asset_definition")
        self.assetTags = try node.get("asset_tags")
        self.assetIsLocal = try node.get("asset_is_local")
        self.amount = try node.get("amount")
        self.accountId = try node.get("account_id")
        self.accountAlias = try node.get("account_alias")
        self.accountTags = try node.get("account_tags")
        self.controlProgram = try node.get("control_program")
        self.referenceData = try node.get("reference_data")
        self.isLocal = try node.get("is_local")
    }
}

class UnspentOutputAPI {
    
    let client: Client
    
    init(client: Client) {
        self.client = client
    }
    
    func query(params: JSON) throws -> Page<UnspentOutput> {
        return try self.client.query(path: "/list-unspent-outputs", params: params)
    }
    
    func queryAll(params: JSON, itemBlock: (UnspentOutput) -> Bool, completion: (Error?) -> Void) throws {
        return try self.client.queryAll(path: "/list-unspent-outputs", params: params, itemBlock: itemBlock, completion: completion)
    }
}
