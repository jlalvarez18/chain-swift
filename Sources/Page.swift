//
//  Page.swift
//  Chain-Swift
//
//  Created by Juan Alvarez on 8/20/17.
//
//

import Foundation
import JSON
import HTTP

class Page<T: NodeInitializable> {
    
    let data: JSON
    let items: [T]
    let lastPage: Bool
    
    private let next: JSON
    private let client: Client
    private let path: String
    private let nextPath: String
    
    init(data: JSON, client: Client, path: String, nextPath: String? = nil) throws {
        self.data = data
        self.path = path
        self.nextPath = nextPath ?? path
        self.client = client
        
        self.next = try data.get("next")
        self.items = try data.get("items")
        
        let _pastPage: Bool? = try data.get("lastPage")
        
        self.lastPage = _pastPage ?? false
    }
    
    convenience init(response: Response, client: Client, path: String, nextPath: String? = nil) throws {
        guard let json = response.json else {
            throw try APIError.createJSONError(response: response)
        }
        
        try self.init(data: json, client: client, path: path, nextPath: nextPath)
    }
    
    func nextPage() throws -> Page<T> {
        let res = try self.client.request(path: self.nextPath, body: self.next)
        
        return try Page<T>(response: res, client: self.client, path: self.path, nextPath: self.nextPath)
    }
}
