//
//  TransactionBuilder.swift
//  Chain-Swift
//
//  Created by Juan Alvarez on 8/21/17.
//
//

import Foundation
import JSON

class TransactionBuilder {
    
    var allowAdditionalActions: Bool = false // If true, build the transaction as a partial transaction.
    var baseTransaction: JSON? // Base transaction provided by a third party.
    
    fileprivate var actions: [JSON] = []
    fileprivate var txnRefData: JSON?
    
    static func build(_ block: (TransactionBuilder) throws -> Void) throws -> TransactionBuilder {
        let builder = TransactionBuilder()
        
        try block(builder)
        
        return builder
    }
    
    // MARK: Issue
    
    func issue(asset: Asset, amount: Int) throws {
        try issue(assetAlias: asset.alias, amount: amount)
    }
    
    func issue(assetAlias: String, amount: Int) throws {
        var params = JSON()
        
        try params.set("type", "issue")
        try params.set("assetAlias", assetAlias)
        try params.set("amount", amount)
        
        self.actions.append(params)
    }
    
    func issue(assetId: String, amount: Int) throws {
        var params = JSON()
        
        try params.set("type", "issue")
        try params.set("assetId", assetId)
        try params.set("amount", amount)
        
        self.actions.append(params)
    }
    
    // MARK: Spend from Account
    
    func spendFrom(account: Account, asset: Asset, amount: Int) throws {
        try spendFrom(accountId: account.id, assetId: asset.id, amount: amount)
    }
    
    func spendFrom(accountId: String, assetId: String, amount: Int) throws {
        var params = JSON()
        
        try params.set("type", "spend_account")
        try params.set("accountId", accountId)
        try params.set("assetId", assetId)
        try params.set("amount", amount)
        
        self.actions.append(params)
    }
    
    func spendFrom(accountAlias: String, assetAlias: String, amount: Int) throws {
        var params = JSON()
        
        try params.set("type", "spend_account")
        try params.set("accountAlias", accountAlias)
        try params.set("assetAlias", assetAlias)
        try params.set("amount", amount)
        
        self.actions.append(params)
    }
    
    // MARK: Spend from Output
    
    func spendUnspentOutput(outputId: String) throws {
        var params = JSON()
        
        try params.set("type", "spend_account_unspent_output")
        try params.set("outputId", outputId)
        
        self.actions.append(params)
    }
    
    // MARK: Control Receiver
    
    func controlWith(receiver: Receiver, asset: Asset, amount: Int) throws {
        try controlWith(receiver: receiver, assetId: asset.id, amount: amount)
    }
    
    func controlWith(receiver: Receiver, assetId: String, amount: Int) throws {
        var params = JSON()
        
        try params.set("type", "control_receiver")
        try params.set("receiver", receiver.makeJSON())
        try params.set("assetId", assetId)
        try params.set("amount", amount)
        
        self.actions.append(params)
    }
    
    func controlWith(receiver: Receiver, assetAlias: String, amount: Int) throws {
        var params = JSON()
        
        try params.set("type", "control_receiver")
        try params.set("receiver", receiver.makeJSON())
        try params.set("assetAlias", assetAlias)
        try params.set("amount", amount)
        
        self.actions.append(params)
    }
    
    // MARK: Control Account
    
    func controlWith(account: Account, asset: Asset, amount: Int) throws {
        try controlWith(accountAlias: account.id, assetAlias: asset.alias, amount: amount)
    }
    
    func controlWith(accountAlias: String, assetAlias: String, amount: Int) throws {
        var params = JSON()
        
        try params.set("type", "control_account")
        try params.set("assetAlias", assetAlias)
        try params.set("accountAlias", accountAlias)
        try params.set("amount", amount)
        
        self.actions.append(params)
    }
    
    func controlWith(accountId: String, assetAlias: String, amount: Int) throws {
        var params = JSON()
        
        try params.set("type", "control_account")
        try params.set("assetAlias", assetAlias)
        try params.set("accountId", accountId)
        try params.set("amount", amount)
        
        self.actions.append(params)
    }
    
    // MARK: Retire
    
    func retire(asset: Asset, amount: Int) throws {
        try retire(assetId: asset.id, amount: amount)
    }
    
    func retire(assetId: String, amount: Int) throws {
        var params = JSON()
        
        try params.set("type", "retire")
        try params.set("assetId", assetId)
        try params.set("amount", amount)
        
        self.actions.append(params)
    }
    
    func retire(assetAlias: String, amount: Int) throws {
        var params = JSON()
        
        try params.set("type", "retire")
        try params.set("assetAlias", assetAlias)
        try params.set("amount", amount)
        
        self.actions.append(params)
    }
    
    // MARK: Transaction
    
    func transaction(referenceData: JSON) throws {
        var params = JSON()
        
        try params.set("type", "set_transaction_reference_data")
        try params.set("referenceData", referenceData)
        
        self.txnRefData = params
    }
}

extension TransactionBuilder: JSONRepresentable {
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        
        var updatedActions = actions
        
        if let refData = self.txnRefData {
            updatedActions.append(refData)
        }
        
        try json.set("actions", updatedActions)
        try json.set("allowAdditionalActions", self.allowAdditionalActions)
        try json.set("baseTransaction", baseTransaction)
        
        return json
    }
}
