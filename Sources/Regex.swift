//
//  Regex.swift
//  Chain-Swift
//
//  Created by Juan Alvarez on 8/19/17.
//
//

import Foundation

class Regex {
    let internalExpression: NSRegularExpression
    let pattern: String
    
    init(_ pattern: String) throws {
        self.pattern = pattern
        self.internalExpression = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
    }
    
    func test(input: String) -> Bool {
        let range = NSMakeRange(0, input.characters.count)
        let matches = self.internalExpression.matches(in: input, options: [], range: range)
        
        return matches.count > 0
    }
}
