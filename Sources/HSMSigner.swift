//
//  HSMSigner.swift
//  Chain-Swift
//
//  Created by Juan Alvarez on 8/20/17.
//
//

import Foundation
import JSON

class Signer {
    private(set) var xpubs: [String] = []
    let connection: Connection
    
    init(connection: Connection) {
        self.connection = connection
    }
    
    func add(key: String) {
        self.xpubs.append(key)
    }
}

class HSMSigner {
    
    typealias Template = JSON
    
    fileprivate var signers: [String: Signer] = [:]
    
    func addKey(key: String, connection: Connection) {
        let token = connection.token ?? "noauth"
        let id = "\(connection.baseUrlString)-\(token)"
        
        let signer: Signer
        
        if let s = self.signers[id] {
            signer = s
        } else {
            signer = Signer(connection: connection)
            
            self.signers[id] = signer
        }
        
        signer.add(key: key)
    }
    
    func sign(template: Template) throws -> Template {
        var nextTemplate = template
        
        // Return early if no signers
        guard self.signers.count > 0 else {
            return nextTemplate
        }
        
        for (_, signer) in self.signers {
            let body: [String: Any] = [
                "transactions": [nextTemplate],
                "xpubs": signer.xpubs
            ]
            
            let res = try signer.connection.request(path: "/sign-transaction", body: body)
            
            nextTemplate = try res.makeResponse().json ?? JSON()
        }
        
        return nextTemplate
    }
    
    func signBatch(templates t: [Template]) throws -> BatchResponse {
        var templates = t.filter { $0.wrapped != .null }
        
        // Return early if no signers
        guard self.signers.count > 0 else {
            return BatchResponse(responses: templates)
        }
        
        var originalIndexes: [Int] = Array(0...templates.count)
        var errors: [JSON] = Array(repeating: .null, count: t.count)
        
        for (_, signer) in self.signers {
            var nextOriginalIndexes: [Int] = []
            
            let body: [String: Any] = [
                "transactions": templates,
                "xpubs": signer.xpubs
            ]
            
            let res = try signer.connection.request(path: "/sign-transaction", body: body).makeResponse()
            
            let batchResponse = BatchResponse(response: res)
            
            for (index, success) in batchResponse.successes.enumerated() {
                templates.append(success)
                nextOriginalIndexes.append(originalIndexes[index])
            }
            
            for (index, error) in batchResponse.errors.enumerated() {
                errors[originalIndexes[index]] = error
            }
            
            originalIndexes = nextOriginalIndexes
        }
        
        var responses: [JSON] = []
        
        for (index, template) in templates.enumerated() {
            responses[originalIndexes[index]] = template
        }
        
        for (index, error) in errors.enumerated() {
            if error != .null {
                responses[index] = error
            }
        }
        
        return BatchResponse(responses: responses)
    }
    
    
    
    
    
    
    
}
