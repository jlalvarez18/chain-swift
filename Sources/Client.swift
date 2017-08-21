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
    
    lazy var accessTokens: AccessTokensAPI = {
        return AccessTokensAPI(client: self)
    }()
    
    lazy var authorizationGrants: AuthorizationGrantsAPI = {
        return AuthorizationGrantsAPI(client: self)
    }()
    
    lazy var accounts: AccountsAPI = {
        return AccountsAPI(client: self)
    }()
    
    lazy var assets: AssetsAPI = {
        return AssetsAPI(client: self)
    }()
    
    lazy var balances: BalancesAPI = {
        return BalancesAPI(client: self)
    }()
    
    lazy var config: ConfigAPI = {
        return ConfigAPI(client: self)
    }()
    
    lazy var mockHsm: MockHSM = {
        let url = "\(self.connection.baseUrlString)/mockhsm"
        let connection = Connection(baseUrl: url, token: self.connection.token, agent: self.connection.agent)
        
        return MockHSM(client: self, signerConnection: connection)
    }()
    
    lazy var transactions: TransactionAPI = {
        return TransactionAPI(client: self)
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
    
    func createBatch(path: String, params: [JSON]) throws -> BatchResponse {
        let _params = try params.map { json -> JSON in
            var newJSON = json
            try newJSON.set("clientToken", UUID().uuidString)
            
            return newJSON
        }
        
        let res = try self.request(path: path, body: JSON(_params))
        
        return BatchResponse(response: res)
    }
    
    func query<T: JSONInitializable>(path: String, nextPath: String? = nil, params: JSON) throws -> Page<T> {
        let response = try self.request(path: path, body: params)
        
        // then create a page object
        return try Page<T>(response: response, client: self, path: path, nextPath: nextPath)
    }
    
    func queryAll<T: JSONInitializable>(path: String, nextPath: String? = nil, params: JSON, itemBlock: (T) -> Bool, completion: (Error?) -> Void) throws {
        var shouldContinue = true
        
        var currentPage: Page<T> = try self.query(path: path, nextPath: nextPath, params: params)
        
        while shouldContinue {
            for item in currentPage.items {
                if itemBlock(item) == false {
                    shouldContinue = false
                    continue
                }
            }
            
            if currentPage.lastPage {
                shouldContinue = false
            }
            
            currentPage = try currentPage.nextPage()
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
