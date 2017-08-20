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
    
    let connection: Connection
    
    static var repositoryName: String = "chain_swift_client"
    
    init(url: String?, accessToken: String, userAgent: String)
    {
        let baseURLString = url ?? "http://localhost:1999"
        self.connection = Connection(baseUrl: baseURLString, token: accessToken, agent: userAgent)
    }
    
    required convenience init(config: Config) throws {
        let token: String = try config.get("accessToken")
        let url: String? = try config.get("url")
        let agent: String = try config.get("agent")
        
        self.init(url: url, accessToken: token, userAgent: agent)
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
