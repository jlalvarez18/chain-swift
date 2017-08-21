//
//  Shared.swift
//  Chain-Swift
//
//  Created by Juan Alvarez on 8/20/17.
//
//

import Foundation
import JSON
import HTTP

//  TODO: add generics to initialize the success items
class BatchResponse {
    
    let successes: [JSON]
    let errors: [JSON]
    
    let responses: [JSON]
    
    init(responses: [JSON]) {
        self.responses = responses
        
        var _successes: [JSON] = Array(repeating: JSON(.null), count: responses.count)
        var _errors: [JSON] = Array(repeating: JSON(.null), count: responses.count)
        
        for (index, res) in responses.enumerated() {
            if res["code"] != nil {
                _errors[index] = res
            } else {
                _successes[index] = res
            }
        }
        
        self.successes = _successes
        self.errors = _errors
    }
    
    convenience init(response: Response) {
        self.init(responses: response.json?.array ?? [])
    }
}
