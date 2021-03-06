//
//  BalancesAPI.swift
//  Chain-Swift
//
//  Created by Juan Alvarez on 8/21/17.
//
//

import Foundation
import JSON
import HTTP

struct Balance: NodeInitializable {
    let amount: Int
    let sumBy: JSON
    
    init(node: Node) throws {
        self.amount = try node.get("amount")
        self.sumBy = try node.get("sumBy")
    }
}

class BalancesAPI {
    
    let client: Client
    
    init(client: Client) {
        self.client = client
    }
    
    func query(params: JSON) throws -> Page<Balance> {
        return try self.client.query(path: "/list-balances", params: params)
    }
    
    func queryAll(params: JSON, itemBlock: (Balance) -> Bool, completion: (Error?) -> Void) throws {
        return try self.client.queryAll(path: "/list-balances", params: params, itemBlock: itemBlock, completion: completion)
    }
}
