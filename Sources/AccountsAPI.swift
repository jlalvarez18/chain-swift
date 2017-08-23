//
//  AccountsAPI.swift
//  Chain-Swift
//
//  Created by Juan Alvarez on 8/20/17.
//
//

import Foundation
import HTTP
import JSON

struct Account: NodeInitializable {
    struct Key: NodeInitializable {
        let rootXpub: String
        let accountXpub: String
        let assetDerivationPath: JSON
        
        init(node: Node) throws {
            self.rootXpub = try node.get("root_xpub")
            self.accountXpub = try node.get("account_xpub")
            self.assetDerivationPath = try node.get("asset_derivation_path")
        }
    }
    
    let id: String
    let alias: String
    let quorum: Int
    let tags: JSON
    let keys: [Key]
    
    init(node: Node) throws {
        self.id = try node.get("id")
        self.alias = try node.get("alias")
        self.quorum = try node.get("quorum")
        self.tags = try node.get("tags")
        self.keys = try node.get("keys")
    }
}

struct AccountCreationRequest {
    let alias: String
    let quorum: Int
    let tags: JSON
    let rootXpubs: [HSMKey]
    
    func params() throws -> JSON {
        var params = JSON()
        
        try params.set("alias", self.alias)
        try params.set("rootXpubs", self.rootXpubs.map { $0.xpub })
        try params.set("quorum", self.quorum)
        try params.set("tags", self.tags)
        
        return params
    }
}

struct Receiver: JSONConvertible {
    let controlProgram: String
    let expiresAt: Date
    
    init(json: JSON) throws {
        self.controlProgram = try json.get("control_program")
        
        let expiresAtString: String = try json.get("expires_at")
        self.expiresAt = Date(rfc3339: expiresAtString)!
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        
        try json.set("control_program", self.controlProgram)
        try json.set("expires_at", self.expiresAt.rfc3339)
        
        return json
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
        
        let json = try self.client.create(path: "/create-account", params: params)
        
        return try Account(node: json)
    }
    
    func createBatch(requests: [AccountCreationRequest]) throws -> BatchResponse {
        let params = try requests.map { try $0.params() }
        
        return try self.client.createBatch(path: "/create-account", params: params)
    }
    
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
    func query(params: JSON) throws -> Page<Account> {
        return try self.client.query(path: "/list-accounts", params: params)
    }
    
    func queryAll(params: JSON, itemBlock: (Account) -> Bool, completion: (Error?) -> Void) throws {
        return try self.client.queryAll(path: "/list-accounts", params: params, itemBlock: itemBlock, completion: completion)
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
        
        let json = try self.client.create(path: "/create-account", params: params)
        
        return try Account(node: json)
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

fileprivate extension AccountsAPI {
    
    func createReceiver(with params: JSON) throws -> Receiver {
        let json = try self.client.create(path: "/create-account-receiver", params: params)
        
        return try Receiver(json: json)
    }
}
