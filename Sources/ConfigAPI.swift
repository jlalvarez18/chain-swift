//
//  ConfigAPI.swift
//  Chain-Swift
//
//  Created by Juan Alvarez on 8/21/17.
//
//

import Foundation
import JSON
import HTTP

struct CoreInfo: JSONInitializable {
    struct Snapshot: JSONInitializable {
        let attempt: Int
        let height: Int
        let size: Int
        let downloaded: Int
        let inProgress: Bool
        
        init(json: JSON) throws {
            self.attempt = try json.get("attempt")
            self.height = try json.get("height")
            self.size = try json.get("size")
            self.downloaded = try json.get("downloaded")
            self.inProgress = try json.get("inProgress")
        }
    }
    
    struct BuildConfig: JSONInitializable {
        let isLocalhostAuth: Bool
        let isMockHsm: Bool
        let isReset: Bool
        let isPlainHttp: Bool
        
        init(json: JSON) throws {
            self.isLocalhostAuth = try json.get("is_localhost_auth")
            self.isMockHsm = try json.get("is_mockHsm")
            self.isReset = try json.get("is_reset")
            self.isPlainHttp = try json.get("is_plain_http")
        }
    }
    
    let snapshot: Snapshot
    let isConfigured: Bool
    let configuredAt: Date
    
    let isSigner: Bool
    let isGenerator: Bool
    
    let generatorUrl: String
    let generatorAccessToken: String
    
    let blockchainId: String
    let blockHeight: Int
    
    let generatorBlockHeight: Int
    let generatorBlockHeightFetchedAt: Date
    
    let isProduction: Bool
    let crosscoreRpcVersion: Int
    
    let coreId: String
    let version: String
    
    let buildCommit: String
    let buildDate: String
    let buildConfig: BuildConfig
    
    let health: JSON
    
    init(json: JSON) throws {
        self.snapshot = try json.get("snapshot")
        self.isConfigured = try json.get("isConfigured")
        
        self.configuredAt = try {
            let string: String = try json.get("configuredAt")
            return Date(rfc3339: string)!
        }()
        
        self.isSigner = try json.get("isSigner")
        self.isGenerator = try json.get("isGenerator")
        
        self.generatorUrl = try json.get("generatorUrl")
        self.generatorAccessToken = try json.get("generatorAccessToken")
        
        self.blockchainId = try json.get("blockchainId")
        self.blockHeight = try json.get("blockHeight")
        
        self.generatorBlockHeight = try json.get("generatorBlockHeight")
        self.generatorBlockHeightFetchedAt = try {
            let string: String = try json.get("generatorBlockHeightFetchedAt")
            return Date(rfc3339: string)!
        }()
        
        self.isProduction = try json.get("isProduction")
        self.crosscoreRpcVersion = try json.get("crosscoreRpcVersion")
        
        self.coreId = try json.get("coreId")
        self.version = try json.get("version")
        
        self.buildCommit = try json.get("buildCommit")
        self.buildDate = try json.get("buildDate")
        self.buildConfig = try json.get("buildConfig")
        
        self.health = try json.get("health")
    }
}

class ConfigAPI {
    
    let client: Client
    
    init(client: Client) {
        self.client = client
    }
    
    func reset(everything: Bool = false) throws {
        var params = JSON()
        try params.set("everything", everything)
        
        let _ = try self.client.request(path: "/reset", body: params)
    }
    
    func configure(isGenerator: Bool, generatorUrl: String, generatorAccessToken: String, blockchainId: String) throws {
        var params = JSON()
        try params.set("isGenerator", isGenerator)
        try params.set("generatorUrl", generatorUrl)
        try params.set("generatorAccessToken", generatorAccessToken)
        try params.set("blockchainId", blockchainId)
        
        let _ = try self.client.request(path: "/configure", body: params)
    }
    
    func info() throws -> CoreInfo {
        let res = try self.client.request(path: "/info", body: JSON())
        
        guard let json = res.json else {
            throw ChainError(.badRequest, reason: "Missing JSON response")
        }
        
        return try CoreInfo(json: json)
    }
}
