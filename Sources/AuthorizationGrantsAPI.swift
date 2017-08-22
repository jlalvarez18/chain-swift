//
//  AuthorizationGrantsAPI.swift
//  Chain-Swift
//
//  Created by Juan Alvarez on 8/20/17.
//
//

import Foundation
import HTTP
import JSON

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

struct AuthorizationGrant: NodeInitializable {
    enum DataType {
        case accessToken(AccessTokenGuardData)
        case X509Data(X509GuardData)
    }
    
    let guardType: AuthGuardType
    let policy: AuthGuardPolicy
    let protected: Bool
    let createdAt: Date
    let guardData: DataType
    
    init(node: Node) throws {
        let type: String = try node.get("guard_type")
        self.guardType = AuthGuardType(rawValue: type)!
        
        let policyType: String = try node.get("policy")
        self.policy = AuthGuardPolicy(rawValue: policyType)!
        
        let dateString: String = try node.get("created_at")
        self.createdAt = Date(rfc3339: dateString)!
        
        self.protected = try node.get("protected")
        
        switch self.guardType {
        case .accessToken:
            let tokenJSON: JSON = try node.get("guard_data")
            let token = try AccessTokenGuardData(node: tokenJSON)
            
            self.guardData = DataType.accessToken(token)
        
        case .x509:
            let certJSON: JSON = try node.get("guard_data")
            let data = try X509GuardData(node: certJSON)
            
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
struct X509GuardData: NodeInitializable {
    struct Subject: NodeConvertible {
        let c: [String]? // Country attribute
        let o: [String]? // Organization attribute
        let ou: [String]? // Organizational Unit attribute
        let l: [String]? // Locality attribute
        let st: [String]? // State/Province attribute
        let street: [String]? // Street Address attribute
        let postalCode: [String]? // Postal Code attribute
        
        let serialNumber: String? // Serial Number attribute
        let cn: String? // Common Name attribute
        
        init(node: Node) throws {
            self.c = try node.get("c")
            self.o = try node.get("o")
            self.ou = try node.get("ou")
            self.l = try node.get("l")
            self.st = try node.get("st")
            self.street = try node.get("street")
            self.postalCode = try node.get("postalCode")
            self.serialNumber = try node.get("serialNumber")
            self.cn = try node.get("cn")
        }
        
        func makeNode(in context: Context?) throws -> Node {
            var node = Node(context)
            
            try node.set("c", self.c)
            try node.set("o", self.o)
            try node.set("ou", self.ou)
            try node.set("l", self.l)
            try node.set("st", self.st)
            try node.set("street", self.street)
            try node.set("postalCode", self.postalCode)
            try node.set("serialNumber", self.serialNumber)
            try node.set("cn", self.cn)
            
            return node
        }
    }
    
    let subject: Subject
    let policy: AuthGuardPolicy
    let protected: Bool
    let createdAt: Date
    
    init(node: Node) throws {
        self.subject = try node.get("subject")
        
        let policyString: String = try node.get("policy")
        self.policy = AuthGuardPolicy(rawValue: policyString)!
        
        let dateString: String = try node.get("createdAt")
        self.createdAt = Date(rfc3339: dateString)!
        
        self.protected = try node.get("protected")
    }
}

struct AccessTokenGuardData: NodeInitializable {
    let id: String
    
    init(node: Node) throws {
        self.id = try node.get("id")
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
            throw ChainError(.badRequest, reason: "Missing JSON response")
        }
        
        return try AccessTokenGuardData(node: json)
    }
    
    func create(with subject: X509GuardData.Subject, policy: AuthGuardPolicy) throws -> X509GuardData {
        var params = JSON()
        try params.set("guardType", AuthGuardType.x509.rawValue)
        try params.set("guardData.subject", try subject.makeNode(in: nil))
        try params.set("policy", policy.rawValue)
        
        let res = try self.client.create(path: "/create-authorization-grant", params: params, skipArray: true)
        
        guard let json = res.json else {
            throw ChainError(.badRequest, reason: "Missing JSON response")
        }
        
        return try X509GuardData(node: json)
    }
    
    func delete(params: JSON) throws -> Response {
        return try self.client.request(path: "/delete-authorization-grant", body: params)
    }
    
    func list() throws -> [AuthorizationGrant] {
        let page: Page<AuthorizationGrant> = try self.client.query(path: "/list-authorization-grants", nextPath: "/list-access-tokens", params: JSON())
        
        return page.items
    }
}
