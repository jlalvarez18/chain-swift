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
    
    func sign(template: Template, completion: (Template) -> Void) throws {
        var nextTemplate = template
        
        defer {
            completion(nextTemplate)
        }
        
        // Return early if no signers
        guard self.signers.count > 0 else {
            return
        }
        
        for (_, signer) in self.signers {
            let body: [String: Any] = [
                "transactions": [nextTemplate],
                "xpubs": signer.xpubs
            ]
            
            let res = try signer.connection.request(path: "/sign-transaction", body: body)
            
            nextTemplate = try res.makeResponse().json ?? JSON()
        }
    }
    
    func signBatch(templates t: [Template], completion: (BatchResponse) -> Void) throws {
        var nextTemplates = t.filter { $0.wrapped != .null }
        
        var errors: [JSON] = Array(repeating: .null, count: t.count)
        
        defer {
            let resp = BatchResponse(responses: nextTemplates)
            completion(resp)
        }
        
        // Return early if no signers
        guard self.signers.count > 0 else {
            return
        }
        
        let originalIndex: [Int] = Array(0...nextTemplates.count)
        
        var nextOriginalIndex: [Int] = []
        
        for (_, signer) in self.signers {
            let body: [String: Any] = [
                "transactions": nextTemplates,
                "xpubs": signer.xpubs
            ]
            
            let res = try signer.connection.request(path: "/sign-transaction", body: body).makeResponse()
            
            let resposes = res.json?.array ?? []
            
            let batchResponse = BatchResponse(responses: resposes)
            
            for (index, success) in batchResponse.successes.enumerated() {
                nextTemplates.append(success)
                nextOriginalIndex.append(originalIndex[index])
            }
            
            for (index, error) in batchResponse.errors.enumerated() {
                errors[originalIndex[index]] = error
            }
        }
        
        
    }
    
    
    
    
    
    
    
}
