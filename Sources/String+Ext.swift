//
//  String+Ext.swift
//  Chain-Swift
//
//  Created by Juan Alvarez on 8/19/17.
//
//

import Foundation

extension String {
    
    enum CaseType {
        case snake
        case camel
    }
    
    func casing(casing: CaseType) -> String {
        switch casing {
        case .snake:
            return self.snakeCased()
        case .camel:
            return self.camelize()
        }
    }
    
    func snakeCased() -> String {
        let pattern = "([a-z0-9])([A-Z])"
        
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: self.characters.count)
        
        return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2").lowercased()
    }
    
    // https://gist.github.com/stevenschobert/540dd33e828461916c11
    func camelize() -> String {
        let source = clean(with: " ", allOf: "-", "_", ".")
        
        if source.characters.contains(" ") {
            let first = source.substring(to: source.index(source.startIndex, offsetBy: 1)).lowercased()
            let cammel = source.capitalized.replacingOccurrences(of: " ", with: "")
            let rest = String(cammel.characters.dropFirst())
            
            return "\(first)\(rest)"
        } else {
            let first = source.substring(to: source.index(source.startIndex, offsetBy: 1)).lowercased()
            let rest = String(source.characters.dropFirst())
            
            return "\(first)\(rest)"
        }
    }
    
    func clean(with: String, allOf: String...) -> String {
        var string = self
        for target in allOf {
            string = string.replacingOccurrences(of: target, with: with)
        }
        return string
    }
    
    func isAllCaps() -> Bool {
        let pattern = "^[A-Z]+$"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        
        let count = regex.numberOfMatches(in: self, options: [], range: NSMakeRange(0, self.characters.count))
        
        return count != 0
    }
}
