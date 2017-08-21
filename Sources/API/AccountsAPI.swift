//
//  AccountsAPI.swift
//  Chain-Swift
//
//  Created by Juan Alvarez on 8/20/17.
//
//

import Foundation
import Vapor

struct AccountKey: JSONInitializable {
    let rootXpub: String
    let accountXpub: String
    let assetDerivationPath: JSON
    
    init(json: JSON) throws {
        self.rootXpub = try json.get("root_xpub")
        self.accountXpub = try json.get("account_xpub")
        self.assetDerivationPath = try json.get("asset_derivation_path")
    }
}

struct Account: JSONInitializable {
    let id: String
    let alias: String
    let quorum: Int
    let tags: JSON
    let keys: [AccountKey]
    
    init(json: JSON) throws {
        self.id = try json.get("id")
        self.alias = try json.get("alias")
        self.quorum = try json.get("quorum")
        self.tags = try json.get("tags")
        
        let _keys: JSON = try json.get("keys")
        
        let keyItems = _keys.array ?? []
        
        self.keys = try keyItems.map { try AccountKey(json: $0) }
    }
}

struct AccountCreationRequest {
    let alias: String
    let quorum: Int
    let tags: JSON
    let rootXpubs: [HSMKey]
    
    func params() throws -> JSON {
        var params = JSON()
        try params.set("alias", alias)
        try params.set("rootXpubs", rootXpubs.map { $0.xpub })
        try params.set("quorum", quorum)
        try params.set("tags", tags)
        
        return params
    }
}

struct Receiver: JSONInitializable {
    let controlProgram: String
    let expiresAt: Date
    
    init(json: JSON) throws {
        self.controlProgram = try json.get("controlProgram")
        
        let expiresAtString: String = try json.get("expiresAt")
        self.expiresAt = Date(rfc3339: expiresAtString)!
    }
}

struct ReceiverCreationRequest {
    let accountAlias: String?
    let accountId: String?
    let expiresAt: Date
    
    func params() throws -> JSON {
        var params = JSON()
        try params.set("accountId", accountId)
        try params.set("accountAlias", accountAlias)
        try params.set("expiresAt", expiresAt.rfc3339)
        
        return params
    }
}

class AccountsAPI {
    
    let client: Client
    
    init(client: Client) {
        self.client = client
    }
    
    func create(request: AccountCreationRequest) throws -> Account {
        let params = try request.params()
        
        let res = try self.client.create(path: "/create-account", params: params)
        
        guard let json = res.json else {
            throw Abort(.badRequest, reason: "Missing JSON response")
        }
        
        return try Account(json: json)
    }
    
    func createBatch(requests: [AccountCreationRequest]) throws -> BatchResponse {
        let items = try requests.map { try $0.params() }
        
        return try self.client.createBatch(path: "/create-account", params: items)
    }
    
    func queryAll(params: JSON, itemBlock: (JSON) -> Bool, completion: (Error?) -> Void) throws {
        return try self.client.queryAll(owner: self, params: params, itemBlock: itemBlock, completion: completion)
    }
    
    // MARK: Receiver
    
    func createReceiver(request: ReceiverCreationRequest) throws -> Receiver {
        let params = try request.params()
        
        return try createReceiver(with: params)
    }
    
    func createReceiverBatch(requests: [ReceiverCreationRequest]) throws -> BatchResponse {
        let items = try requests.map { try $0.params() }
        
        return try self.client.createBatch(path: "/create-account-receiver", params: items)
    }
    
    // TODO: batch requests
}

// MARK: Convenience Methods

extension AccountsAPI {
    
    func create(alias: String, rootXpubs: [HSMKey], quorum: Int, tags: JSON) throws -> Account {
        var params = JSON()
        try params.set("alias", alias)
        try params.set("rootXpubs", rootXpubs.map { $0.xpub })
        try params.set("quorum", quorum)
        try params.set("tags", tags)
        
        let res = try self.client.create(path: "/create-account", params: params)
        
        guard let json = res.json else {
            throw Abort(.badRequest, reason: "Missing JSON response")
        }
        
        return try Account(json: json)
    }
    
    func createReceiver(accountId: String, expiresAt: Date) throws -> Receiver {
        var params = JSON()
        try params.set("accountId", accountId)
        try params.set("expiresAt", expiresAt.rfc3339)
        
        return try createReceiver(with: params)
    }
    
    func createReceiver(accountAlias: String, expiresAt: Date) throws -> Receiver {
        var params = JSON()
        try params.set("accountAlias", accountAlias)
        try params.set("expiresAt", expiresAt.rfc3339)
        
        return try createReceiver(with: params)
    }
}

extension AccountsAPI: Queryable {
    
    /**
     * Get one page of accounts matching the specified query.
     *
     * @param {Object} params={} - Filter and pagination information.
     * @param {String} params.filter - Filter string, see {@link https://chain.com/docs/core/build-applications/queries}.
     * @param {Array<String|Number>} params.filterParams - Parameter values for filter string (if needed).
     * @param {Number} params.pageSize - Number of items to return in result set.
     * @param {pageCallback} [callback] - Optional callback. Use instead of Promise return value as desired.
     * @returns {Promise<Page<Account>>} Requested page of results.
     */
    func query(params: JSON) throws -> Page {
        return try self.client.query(owner: self, path: "/list-accounts", params: params)
    }
}

fileprivate extension AccountsAPI {
    
    func createReceiver(with params: JSON) throws -> Receiver {
        let res = try self.client.create(path: "/create-account-receiver", params: params)
        
        guard let json = res.json else {
            throw Abort(.badRequest, reason: "Missing JSON response")
        }
        
        return try Receiver(json: json)
    }
}
