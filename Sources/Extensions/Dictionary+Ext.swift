//
//  Dictionary+Ext.swift
//  Chain-Swift
//
//  Created by Juan Alvarez on 8/19/17.
//
//

import Foundation

extension Dictionary {
    
    func keysToCamelCase() -> Dictionary {
        return Dictionary.walkForCamelCasing(obj: self, casing: .camel) as! Dictionary
    }
    
    func keysToSnake() -> Dictionary {
        return Dictionary.walkForCamelCasing(obj: self, casing: .snake) as! Dictionary
    }
    
    private static func walkForCamelCasing(obj: Any, casing: String.CaseType) -> Any {
        if let dict = obj as? [String: Any] {
            var newDict: [String: Any] = [:]
            
            for (k, v) in dict {
                let camelKey = k.casing(casing: casing)
                
                newDict[camelKey] = walkForCamelCasing(obj: v, casing: casing)
            }
            
            return newDict
        }
        
        if let a = obj as? [Any] {
            return a.map { (a) -> Any in
                return walkForCamelCasing(obj: a, casing: casing)
            }
        }
        
        return obj
    }
}
