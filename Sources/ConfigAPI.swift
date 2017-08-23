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

struct CoreInfo: NodeInitializable {
    struct Snapshot: NodeInitializable {
        let attempt: Int
        let height: Int
        let size: Int
        let downloaded: Int
        let inProgress: Bool
        
        init(node: Node) throws {
            self.attempt = try node.get("attempt")
            self.height = try node.get("height")
            self.size = try node.get("size")
            self.downloaded = try node.get("downloaded")
            self.inProgress = try node.get("in_progress")
        }
    }
    
    struct BuildConfig: NodeInitializable {
        let isLocalhostAuth: Bool
        let isMockHsm: Bool
        let isReset: Bool
        let isPlainHttp: Bool
        
        init(node: Node) throws {
            self.isLocalhostAuth = try node.get("is_localhost_auth")
            self.isMockHsm = try node.get("is_mockHsm")
            self.isReset = try node.get("is_reset")
            self.isPlainHttp = try node.get("is_plain_http")
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
    
    init(node: Node) throws {
        self.snapshot = try node.get("snapshot")
        self.isConfigured = try node.get("is_configured")
        
        self.configuredAt = try {
            let string: String = try node.get("configured_at")
            return Date(rfc3339: string)!
        }()
        
        self.isSigner = try node.get("is_signer")
        self.isGenerator = try node.get("is_generator")
        
        self.generatorUrl = try node.get("generator_url")
        self.generatorAccessToken = try node.get("generator_access_token")
        
        self.blockchainId = try node.get("blockchain_id")
        self.blockHeight = try node.get("block_height")
        
        self.generatorBlockHeight = try node.get("generator_block_height")
        self.generatorBlockHeightFetchedAt = try {
            let string: String = try node.get("generator_blockHeight_fetchedAt")
            return Date(rfc3339: string)!
        }()
        
        self.isProduction = try node.get("is_production")
        self.crosscoreRpcVersion = try node.get("crosscore_rpc_version")
        
        self.coreId = try node.get("core_id")
        self.version = try node.get("version")
        
        self.buildCommit = try node.get("build_commit")
        self.buildDate = try node.get("build_date")
        self.buildConfig = try node.get("build_config")
        
        self.health = try node.get("health")
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
            throw try APIError.createJSONError(response: res)
        }
        
        return try CoreInfo(node: json)
    }
}
