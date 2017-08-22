//
//  TransactionAPI.swift
//  Chain-Swift
//
//  Created by Juan Alvarez on 8/21/17.
//
//

import Foundation
import JSON
import HTTP

struct Transaction: JSONInitializable {
    let id: String
    let timestamp: Date
    let blockId: String
    let blockHeight: Int
    let position: Int
    let referenceData: JSON
    let isLocal: Bool
    
    let inputs: [TransactionInput]
    let outputs: [TransactionOutput]
    
    init(json: JSON) throws {
        self.id = try json.get("id")
        self.timestamp = try {
            let string: String = try json.get("timestamp")
            return Date(rfc3339: string)!
        }()
        self.blockId = try json.get("block_id")
        self.blockHeight = try json.get("block_height")
        self.position = try json.get("position")
        self.referenceData = try json.get("reference_data")
        self.isLocal = try json.get("is_local")
        self.inputs = try json.get("inputs")
        self.outputs = try json.get("outputs")
    }
}

struct TransactionInput: JSONInitializable {
    let type: String
    
    let assetId: String
    let assetAlias: String?
    let assetDefinition: JSON?
    let assetTags: JSON?
    let assetIsLocal: Bool
    
    let amount: Int
    let spentOutputId: String?
    let accountId: String?
    let accountAlias: String?
    let accountTags: String?
    
    let issuanceProgram: String?
    
    let referenceData: JSON?
    
    let isLocal: Bool
    
    init(json: JSON) throws {
        self.type = try json.get("type")
        self.assetId = try json.get("asset_id")
        self.assetAlias = try json.get("asset_alias")
        self.assetDefinition = try json.get("asset_definition")
        self.assetTags = try json.get("asset_tags")
        self.assetIsLocal = try json.get("asset_is_local")
        self.amount = try json.get("amount")
        self.spentOutputId = try json.get("spent_output_id")
        self.accountId = try json.get("account_id")
        self.accountAlias = try json.get("account_alias")
        self.accountTags = try json.get("account_tags")
        self.issuanceProgram = try json.get("issuance_program")
        self.referenceData = try json.get("reference_data")
        self.isLocal = try json.get("is_local")
    }
}

struct TransactionOutput: JSONInitializable {
    let id: String
    let type: String // The type of the output. Possible values are "control" and "retire".
    let purpose: String // The purpose of the output. Possible values are "receive" and "change".
    let position: Int
    
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
    
    init(json: JSON) throws {
        self.id = try json.get("id")
        self.type = try json.get("type")
        self.purpose = try json.get("purpose")
        self.position = try json.get("position")
        self.assetId = try json.get("asset_id")
        self.assetAlias = try json.get("asset_alias")
        self.assetDefinition = try json.get("asset_definition")
        self.assetTags = try json.get("asset_tags")
        self.assetIsLocal = try json.get("asset_is_local")
        self.amount = try json.get("amount")
        self.accountId = try json.get("account_id")
        self.accountAlias = try json.get("account_alias")
        self.accountTags = try json.get("account_tags")
        self.controlProgram = try json.get("control_program")
        self.referenceData = try json.get("reference_data")
        self.isLocal = try json.get("is_local")
    }
}

class TransactionAPI {
    
    let client: Client
    
    init(client: Client) {
        self.client = client
    }
    
    func build(_ block: (TransactionBuilder) throws -> Void) throws -> JSON {
        let builder = try TransactionBuilder.build(block)
        
        let res = try self.client.request(path: "/build-transaction", body: [builder.makeJSON()])
        
        guard let json = res.json else {
            throw ChainError(.badRequest, reason: "Missing JSON response")
        }
        
        try checkForError(json: json)
        
        return json
    }
    
    func buildBatch(builders: [TransactionBuilder]) throws -> BatchResponse {
        let body = try builders.map { try $0.makeJSON() }
        
        return try self.client.createBatch(path: "/build-transaction", params: body)
    }
    
    func sign(template: JSON) throws -> JSON {
        let finalized = try finalize(template: template)
        
        return try self.client.signer.sign(template: finalized)
    }
    
    func signBatch(templates: [JSON]) throws -> BatchResponse {
        let finalized = try finalizeBatch(templates: templates)
        
        return try self.client.signer.signBatch(templates: finalized.successes)
    }
    
    func submit(signed: JSON) throws -> JSON {
        var body = JSON()
        try body.set("transactions", [signed])
        
        let res = try self.client.request(path: "/submit-transaction", body: body)
        
        guard let json = res.json else {
            throw ChainError(.badRequest, reason: "Missing JSON response")
        }
        
        try checkForError(json: json)
        
        return json
    }
    
    func submitBatch(signed: [JSON]) throws -> BatchResponse {
        var body = JSON()
        try body.set("transactions", signed)
        
        let res = try self.client.request(path: "/submit-transaction", body: body)
        
        return BatchResponse(response: res)
    }
    
    func query(params: JSON) throws -> Page<Transaction> {
        return try self.client.query(path: "/list-transactions", params: params)
    }
    
    func queryAll(params: JSON, itemBlock: (Transaction) -> Bool, completion: (Error?) -> Void) throws {
        return try self.client.queryAll(path: "/list-transactions", params: params, itemBlock: itemBlock, completion: completion)
    }
}

fileprivate extension TransactionAPI {
    
    func checkForError(json: JSON) throws {
        /*
        if ('code' in resp) {
            throw errors.create(
                errors.types.BAD_REQUEST,
                errors.formatErrMsg(resp, ''),
                {body: resp}
            )
        }
        return resp
        */
        
        guard let first = json.array?.first else {
            return
        }
        
        let code: String? = try first.get("code")
        
        if let _ = code {
            throw ChainError(.badRequest, reason: first.wrapped.description)
        }
    }
    
    // TODO: implement finalize when Chain implements it
    func finalize(template: JSON) throws -> JSON {
        return template
    }
    
    // TODO: implement finalizeBatch when Chain implements it
    func finalizeBatch(templates: [JSON]) throws -> BatchResponse {
        return BatchResponse(responses: templates)
    }
}




















