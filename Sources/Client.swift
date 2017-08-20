//
//  Client.swift
//  Chain-Swift
//
//  Created by Juan Alvarez on 8/20/17.
//
//

import Foundation
import Vapor

class Client {
    
    static var repositoryName: String = "chain_swift_client"
    
    let connection: Connection
    let signer: HSMSigner
    
    lazy var mockHsm: MockHSMAPI = {
        let url = "\(self.connection.baseUrlString)/mockhsm"
        let connection = Connection(baseUrl: url, token: self.connection.token, agent: self.connection.agent)
        
        return MockHSMAPI(client: self, signerConnection: connection)
    }()
    
    lazy var accessTokens: AccessTokensAPI = {
        return AccessTokensAPI(client: self)
    }()
    
    init(url: String?, accessToken: String, userAgent: String) {
        let baseURLString = url ?? "http://localhost:1999"
        
        self.connection = Connection(baseUrl: baseURLString, token: accessToken, agent: userAgent)
        self.signer = HSMSigner()
    }
    
    required convenience init(config: Config) throws {
        let token: String = try config.get("accessToken")
        let url: String? = try config.get("url")
        let agent: String = try config.get("agent")
        
        self.init(url: url, accessToken: token, userAgent: agent)
    }
    
    func request(path: String, body: JSON) throws -> Response {
        return try self.connection.request(path: path, body: body)
    }
    
    func create(path: String, params: JSON, skipArray: Bool = false) throws -> Response {
        var body = params
        try body.set("clientToken", UUID().uuidString)
        
        if !skipArray {
            body = [body]
        }
        
        return try self.request(path: path, body: body)
    }
    
    func query(owner: Queryable, path: String, params: JSON) throws -> Page {
        let response = try self.request(path: path, body: params)
        
        // then create a page object
        return try Page(data: response.json ?? JSON(), client: self, owner: owner)
    }
    
    func queryAll(owner: Queryable, params: JSON, itemBlock: (JSON) -> Bool, completion: (Error?) -> Void) throws {
        var nextParams = params
        
        var shouldContinue = true
        
        while shouldContinue {
            let page = try owner.query(params: nextParams)
            
            let items = page.items.array ?? []
            
            for item in items {
                if itemBlock(item) == false {
                    shouldContinue = false
                    continue
                }
            }
            
            if page.lastPage {
                shouldContinue = false
            } else {
                nextParams = page.next
            }
        }
        
        completion(nil)
    }
}

extension Client: Provider {

    func boot(_ config: Config) throws {
        
    }
    
    func boot(_ droplet: Droplet) throws {
        self.connection.client = droplet.client
    }
    
    func beforeRun(_ droplet: Droplet) throws {
        
    }
}
