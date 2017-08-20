//
//  Page.swift
//  Chain-Swift
//
//  Created by Juan Alvarez on 8/20/17.
//
//

import Foundation
import JSON

protocol Queryable {
    func query(params: JSON) throws -> Page
}

class Page {
    
    let data: JSON
    let client: Client
    let owner: Queryable
    let lastPage: Bool
    
    let next: JSON
    let items: JSON
    
    init(data: JSON, client: Client, owner: Queryable) throws {
        self.data = data
        self.client = client
        self.owner = owner
        
        self.next = try data.get("next")
        self.items = try data.get("items")
        
        let _pastPage: Bool? = try data.get("lastPage")
        
        self.lastPage = _pastPage ?? false
    }
    
    func nextPage() throws -> Page {
        return try self.owner.query(params: self.next)
    }
}
