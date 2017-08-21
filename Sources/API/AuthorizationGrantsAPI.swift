//
//  AuthorizationGrantsAPI.swift
//  Chain-Swift
//
//  Created by Juan Alvarez on 8/20/17.
//
//

import Foundation
import Vapor

/**
 * Authorization grants provide a mapping from guard objects (access tokens or X509
 * certificates) to a list of predefined Chain Core access policies.
 *
 * * **client-readwrite**: full access to the Client API
 * * **client-readonly**: access to read-only Client endpoints
 * * **monitoring**: access to monitoring-specific endpoints
 * * **crosscore**: access to the cross-core API, including fetching blocks and
 *   submitting transactions to the generator, but not including block signing
 * * **crosscore-signblock**: access to the cross-core API's block singing
 *   functionality
 */

enum AuthGuardPolicy: String {
    case clientReadWrite = "client-readwrite"
    case clientReadOnly = "client-readonly"
    case monitoring = "monitoring"
    case crosscore = "crosscore"
    case crosscoreSignblock = "crosscore-signblock"
}

enum AuthGuardType: String {
    case accessToken = "access_token"
    case x509 = "x509"
}

struct AuthorizationGrant: JSONInitializable {
    enum DataType {
        case accessToken(AccessTokenGuardData)
        case X509Data(X509GuardData)
    }
    
    let guardType: AuthGuardType
    let policy: AuthGuardPolicy
    let protected: Bool
    let createdAt: Date
    let guardData: DataType
    
    init(json: JSON) throws {
        let type: String = try json.get("guardType")
        self.guardType = AuthGuardType(rawValue: type)!
        
        let policyType: String = try json.get("policy")
        self.policy = AuthGuardPolicy(rawValue: policyType)!
        
        let dateString: String = try json.get("createdAt")
        self.createdAt = Date(rfc3339: dateString)!
        
        self.protected = try json.get("protected")
        
        switch self.guardType {
        case .accessToken:
            let tokenJSON: JSON = try json.get("guardData")
            let token = try AccessTokenGuardData(json: tokenJSON)
            
            self.guardData = DataType.accessToken(token)
        
        case .x509:
            let certJSON: JSON = try json.get("guardData")
            let data = try X509GuardData(json: certJSON)
            
            self.guardData = DataType.X509Data(data)
        }
    }
}

/*
 * x509 certificates are identified by their Subject attribute. You can
 * configure the guard by specifying values for the Subject's sub-attributes,
 * such as CN or OU. If a certificate's Subject contains all of the
 * sub-attribute values specified in the guard, the guard will produce a
 * positive match.
 */
struct X509GuardData: JSONInitializable {
    struct Subject: JSONConvertible {
        let c: [String]? // Country attribute
        let o: [String]? // Organization attribute
        let ou: [String]? // Organizational Unit attribute
        let l: [String]? // Locality attribute
        let st: [String]? // State/Province attribute
        let street: [String]? // Street Address attribute
        let postalCode: [String]? // Postal Code attribute
        
        let serialNumber: String? // Serial Number attribute
        let cn: String? // Common Name attribute
        
        init(json: JSON) throws {
            self.c = try json.get("c")
            self.o = try json.get("o")
            self.ou = try json.get("ou")
            self.l = try json.get("l")
            self.st = try json.get("st")
            self.street = try json.get("street")
            self.postalCode = try json.get("postalCode")
            self.serialNumber = try json.get("serialNumber")
            self.cn = try json.get("cn")
        }
        
        func makeJSON() throws -> JSON {
            var json = JSON()
            
            try json.set("c", self.c)
            try json.set("o", self.o)
            try json.set("ou", self.ou)
            try json.set("l", self.l)
            try json.set("st", self.st)
            try json.set("street", self.street)
            try json.set("postalCode", self.postalCode)
            try json.set("serialNumber", self.serialNumber)
            try json.set("cn", self.cn)
            
            return json
        }
    }
    
    let subject: Subject
    let policy: AuthGuardPolicy
    let protected: Bool
    let createdAt: Date
    
    init(json: JSON) throws {
        self.subject = try json.get("subject")
        
        let policyString: String = try json.get("policy")
        self.policy = AuthGuardPolicy(rawValue: policyString)!
        
        let dateString: String = try json.get("createdAt")
        self.createdAt = Date(rfc3339: dateString)!
        
        self.protected = try json.get("protected")
    }
}

struct AccessTokenGuardData {
    let id: String
    
    init(json: JSON) throws {
        self.id = try json.get("id")
    }
}

class AuthorizationGrantsAPI {
    
    let client: Client
    
    init(client: Client) {
        self.client = client
    }
    
    func create(with token: AccessToken, policy: AuthGuardPolicy) throws -> AccessTokenGuardData {
        var params = JSON()
        try params.set("guardType", AuthGuardType.accessToken.rawValue)
        try params.set("guardData", ["id": token.id])
        try params.set("policy", policy.rawValue)
        
        let res = try self.client.create(path: "/create-authorization-grant", params: params, skipArray: true)
        
        guard let json = res.json else {
            throw Abort(.badRequest, reason: "Invalid JSON response")
        }
        
        return try AccessTokenGuardData(json: json)
    }
    
    func create(with subject: X509GuardData.Subject, policy: AuthGuardPolicy) throws -> X509GuardData {
        var params = JSON()
        try params.set("guardType", AuthGuardType.x509.rawValue)
        try params.set("guardData.subject", try subject.makeJSON())
        try params.set("policy", policy.rawValue)
        
        let res = try self.client.create(path: "/create-authorization-grant", params: params, skipArray: true)
        
        guard let json = res.json else {
            throw Abort(.badRequest, reason: "Invalid JSON response")
        }
        
        return try X509GuardData(json: json)
    }
    
    func delete(params: JSON) throws -> Response {
        return try self.client.request(path: "/delete-authorization-grant", body: params)
    }
    
    func list() throws -> [AuthorizationGrant] {
        let page: Page<AuthorizationGrant> = try self.client.query(path: "/list-authorization-grants", nextPath: "/list-access-tokens", params: JSON())
        
        return page.items
    }
}
